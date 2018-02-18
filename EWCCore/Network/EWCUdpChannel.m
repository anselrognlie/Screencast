//
//  EWCUdpChannel.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/01/30.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCUdpChannel.h"
#import "EWCUdpChannel+EWCUdpChannelProtected.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import "EWCBufferedPacket.h"
#import "../CoreFoundation/EWCCFTypeRef.h"
#import "EWCAddressIpv4.h"

static void HandleSocketCallback(CFSocketRef s,
                                 CFSocketCallBackType type,
                                 CFDataRef address,
                                 const void *data,
                                 void *info);

static void HandleTimerCallBack(CFRunLoopTimerRef timer, void *info);

@interface EWCUdpChannel()
@property NSRunLoop *runLoop;
@property (nonatomic) CFSocketRef localSocket;
@property (nonatomic) CFRunLoopSourceRef socketSource;
@property (nonatomic) CFRunLoopTimerRef timeoutTimer;
@property NSMutableArray<EWCBufferedPacket *> *transmitBuffer;
@property (readonly) uint16_t listenerPort;
@property (readonly) BOOL enableBroadcast;
@property void(^timeoutOperation)(void);
@end

@implementation EWCUdpChannel {
    BOOL canWrite_;
    struct sockaddr_in boundAddr_;
    CFTimeInterval timerInterval_;
    BOOL timerEnabled_;
    int timeoutRepeatCount_;
}

// initializer /////////////////////////////////////////////////

- (instancetype)init {
    self = [super init];
    
    _localSocket = nil;
    _socketSource = nil;
    _timeoutTimer = nil;
    _runLoop = nil;
    canWrite_ = NO;
    timerInterval_ = 0;
    timerEnabled_ = NO;
    self.transmitBuffer = [NSMutableArray<EWCBufferedPacket *> array];

    memset(&boundAddr_, 0, sizeof(boundAddr_));
    
    return self;
}

- (void)dealloc {
    [self stopSocket];

    self.runLoop = nil;
    self.transmitBuffer = nil;
}

// public entry points ////////////////////////////////////////////////

- (void)start {
    [self startOnRunLoop:[NSRunLoop currentRunLoop]];
}

- (void)startOnRunLoop:(NSRunLoop *)runLoop {
    // note the run loop
    self.runLoop = runLoop;
    
    [self startSocket];
}

- (void)stop {
    [self stopSocket];
}

- (EWCAddressIpv4 *)getBoundAddress {
    return [EWCAddressIpv4 addressWithAddress:&boundAddr_];
}

// private methods ///////////////////////////////////////////////////////

- (void)startSocket {
    NSLog(@"starting socket...");
    
    int newSocket = [self prepareSocket];
    if (! newSocket) {
        return;
    }
    
    // initialize a context to hold our self reference for event handling
    CFSocketContext ctx = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    // get a core foundation socket with our callback handler
    CFSocketRef sock = CFSocketCreateWithNative(kCFAllocatorDefault,
                                                newSocket,
                                                kCFSocketDataCallBack | kCFSocketWriteCallBack,
                                                &HandleSocketCallback,
                                                &ctx);
    self.localSocket = sock;
    CFRelease(sock);
    
    // set option to free the socket once it is invalidated
    CFOptionFlags flags = CFSocketGetSocketFlags(sock);
    flags |= kCFSocketCloseOnInvalidate;
    CFSocketSetSocketFlags(sock, flags);
    
    // create a run loop source for the socket to get notified of events
    CFRunLoopSourceRef socksrc = CFSocketCreateRunLoopSource(kCFAllocatorDefault, sock, 0);
    self.socketSource = socksrc;
    CFRelease(socksrc);
    
    // add the source to the run loop
    CFRunLoopAddSource([self.runLoop getCFRunLoop], socksrc, kCFRunLoopDefaultMode);

    // schedule a timer to detect timeouts
    [self startTimeoutTimer];
    
    NSLog(@"listening...");
}

- (void)stopSocket {
    NSLog(@"shutting down...");

    // invalidate (and free) timer
    if (self.timeoutTimer) {
        CFRunLoopRemoveTimer([self.runLoop getCFRunLoop],
                             self.timeoutTimer,
                             kCFRunLoopDefaultMode);
        self.timeoutTimer = nil;
    }

    // remove and release the run loop source
    if (self.socketSource) {
        CFRunLoopRemoveSource([self.runLoop getCFRunLoop],
                              self.socketSource,
                              kCFRunLoopDefaultMode);
        self.socketSource = nil;
    }

    // invalidate (and free) listening socket
    if (self.localSocket) {
        CFSocketInvalidate(self.localSocket);
        self.localSocket = nil;
    }

    NSLog(@"stopped.");
}

- (void)setLocalSocket:(CFSocketRef)value {
    EWCSwapCFTypeRef(&_localSocket, &value);
}

- (void)setSocketSource:(CFRunLoopSourceRef)value {
    EWCSwapCFTypeRef(&_socketSource, &value);
}

- (void)setTimeoutTimer:(CFRunLoopTimerRef)value {
    EWCSwapCFTypeRef(&_timeoutTimer, &value);
}

- (int)prepareSocket {
    // make sure the listener port has been overridden
    uint16_t port = self.listenerPort;
    
    int localSocket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (localSocket <= 0) {
        return 0;
    }
    
    if (self.enableBroadcast) {
        int enable = 1;
        int error = setsockopt(localSocket,
                               SOL_SOCKET,
                               SO_BROADCAST,
                               (void *)&enable,
                               sizeof(enable));
        if (error) { return 0; }
    }
    
    struct sockaddr_in sockaddr;
    memset(&sockaddr, 0, sizeof(sockaddr));
    sockaddr.sin_len = sizeof(sockaddr);
    sockaddr.sin_family = AF_INET;
    sockaddr.sin_port = htons(port);
    sockaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    
    int status = bind(localSocket, (struct sockaddr *)&sockaddr, sizeof(sockaddr));
    if (status == -1) {
        close(localSocket);
        return 0;
    }

    // get the actual bound addr
    socklen_t socklen = sizeof(boundAddr_);
    status = getsockname(localSocket, (struct sockaddr *)&boundAddr_, &socklen);

    return localSocket;
}

-(void)handleCallbackWithSocket:(CFSocketRef)s
                   callbackType:(CFSocketCallBackType)type
                        address:(CFDataRef)addr
                           data:(const void *)data {
    // process the socket event
    if (type == kCFSocketDataCallBack) {
        NSLog(@"received packet.");
        
        // who connected
        struct sockaddr_in remoteSocket;
        uint8_t *octet;
        if (CFDataGetLength(addr) != sizeof(remoteSocket)) {
            return;
        }
        CFDataGetBytes(addr, CFRangeMake(0, sizeof(remoteSocket)), (UInt8 *)&remoteSocket);
        in_addr_t ipaddr = ntohl(remoteSocket.sin_addr.s_addr);
        octet = (uint8_t *)&ipaddr;
        NSLog(@"remote addr: %d.%d.%d.%d:%d", octet[3], octet[2], octet[1], octet[0],
              ntohs(remoteSocket.sin_port));
        
        // what was sent
        CFDataRef dataRef = (CFDataRef)data;
        NSData *bytes = (__bridge_transfer NSData *)CFDataCreateCopy(kCFAllocatorDefault, dataRef);

        EWCAddressIpv4 *address = [EWCAddressIpv4 addressWithAddress:&remoteSocket];

        // we got a packet, so disable the timer until the next send
        timerEnabled_ = NO;

        // notify overridden handler
        [self handlePacketData:bytes fromAddress:address];
    } else if (type == kCFSocketWriteCallBack) {
        canWrite_ = YES;
        
        [self sendBufferedData];
    }
}

- (void)handleCallbackWithTimer:(CFRunLoopTimerRef)timer {
    // if the interval is 0, then the client isn't interested in timeouts
    if (! timerEnabled_) { return; }

    // are we automatically handling the timeout?
    if (self.timeoutOperation) {
        if (timeoutRepeatCount_) {
            --timeoutRepeatCount_;
            self.timeoutOperation();
        } else {
            [self completeAction];
            [self handleRetriesExceeded];
        }
    } else {
        // we don't have any registered handler, so pass this on to the subclass
        [self handleTimeout];
    }
}

- (void)sendBufferedData {
    // if no data, or unable to send, just exit for now
    if (! canWrite_ || ! self.transmitBuffer.count) { return; }
    
    EWCBufferedPacket *packet = self.transmitBuffer.firstObject;
    
    CFSocketError error;
    error = CFSocketSendData(self.localSocket, packet.address, packet.data, 0);
    
    if (error == kCFSocketSuccess) {
        // remove the data so that it isn't sent again
        [self.transmitBuffer removeObjectAtIndex:0];

        // reset the timeout interval
        [self rescheduleTimeout];
    } else {
        // mark that we're not ready to send
        canWrite_ = NO;
    }
}

- (void)startTimeoutTimer {
    NSLog(@"starting timer...");

    // initialize a context to hold our self reference for event handling
    CFRunLoopTimerContext ctx = {0, (__bridge void *)(self), NULL, NULL, NULL};

    // get a core foundation socket with our callback handler
    CFTimeInterval tenYear = (CFTimeInterval)(60 * 60 * 24 * 365 * 10);
    CFAbsoluteTime firstFire = CFAbsoluteTimeGetCurrent();
    firstFire += tenYear;  // we don't really want it to fire, so schedule ten years
    CFRunLoopTimerRef timer = CFRunLoopTimerCreate(kCFAllocatorDefault,
                                                   firstFire,
                                                   tenYear,
                                                   0,
                                                   0,
                                                   &HandleTimerCallBack,
                                                   &ctx);

    self.timeoutTimer = timer;
    CFRelease(timer);

    // add the timer to the run loop
    CFRunLoopAddTimer([self.runLoop getCFRunLoop], timer, kCFRunLoopDefaultMode);
}

- (void)rescheduleTimeout {
    // if the interval is non zero, schedule the next firing
    if (timerInterval_ > 0) {
        timerEnabled_ = YES;
        CFRunLoopTimerSetNextFireDate(self.timeoutTimer,
                                      CFAbsoluteTimeGetCurrent() + timerInterval_);
    } else {
        timerEnabled_ = NO;
    }
}

// EWCUdpChannelProtected interface ///////////////////////////////////////////////////////

- (void)sendPacketData:(NSData *)data toAddress:(EWCAddressIpv4 *)address {
    // populate the subsystem format address
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(struct sockaddr_in));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(address.port);
    addr.sin_addr.s_addr = htonl(address.addressIpv4);

    // wrap the data and address for transmission
    CFDataRef dataRef = (__bridge_retained CFDataRef)[data copy];
    CFDataRef addrRef = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr, sizeof(addr));
    
    // buffer the data until we're allowed to send
    [self.transmitBuffer addObject:[EWCBufferedPacket packetWithData:dataRef address:addrRef]];
    
    CFRelease(dataRef);
    CFRelease(addrRef);
    
    // attempt to send buffered data
    [self sendBufferedData];
}

- (void)broadcastPacketData:(NSData *)data port:(uint16_t)port {
    // do nothing if we aren't enabled for broadcast
    if (! self.enableBroadcast) { return; }

    EWCAddressIpv4 *address = [EWCAddressIpv4 addressWithAddressIpv4:INADDR_BROADCAST
                                                                port:port];

    [self sendPacketData:data toAddress:address];
}

- (void)setTimeout:(CFTimeInterval)interval {
    timerInterval_ = interval;

    [self rescheduleTimeout];
}

- (void)repeatWithTimeout:(CFTimeInterval)timeout
                     upTo:(int)times
                   action:(void(^)(void))action {
    timeoutRepeatCount_ = times;
    self.timeoutOperation = action;
    [self setTimeout:timeout];

    self.timeoutOperation();
}

- (void)completeAction {
    self.timeoutOperation = nil;
    timeoutRepeatCount_ = 0;
    [self setTimeout:0];
}

// protected overrides //////////////////////////////////////////////

- (uint16_t)listenerPort {
    // does not require override if any local port is ok
    return 0;
}

- (void)handlePacketData:(NSData *)data fromAddress:(EWCAddressIpv4 *)address {
    NSLog(@"subclass must override (void)handlePacketData:fromAddress:");
}

- (void)handleTimeout {
    // does not require override if no timeout handling required
}

- (void)handleRetriesExceeded {
    // does not require override if no timeout handling required
}

- (BOOL)enableBroadcast {
    // does not require override if no broadcast required
    return NO;
}

@end

// static entry points //////////////////////////////////////////////

static void HandleSocketCallback(CFSocketRef s,
                                 CFSocketCallBackType type,
                                 CFDataRef address,
                                 const void *data,
                                 void *info) {
    EWCUdpChannel *listener = (__bridge EWCUdpChannel *)(info);
    [listener handleCallbackWithSocket:s callbackType:type address:address data:data];
}

static void HandleTimerCallBack(CFRunLoopTimerRef timer, void *info) {
    EWCUdpChannel *listener = (__bridge EWCUdpChannel *)(info);
    [listener handleCallbackWithTimer:timer];
}
