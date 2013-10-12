#import "AppDelegate.h"
#include "SimplePing.h"
#include "ServerItem.h"

#include <sys/socket.h>
#include <netdb.h>

#pragma mark * Utilities

NSMutableArray *list;
NSMenuItem *listItem;
NSStatusItem *menuItem;
NSImage *common, *highlight, *ok;
int test = 0;

static NSString * DisplayAddressForAddress(NSData * address)
// Returns a dotted decimal string for the specified address (a (struct sockaddr)
// within the address NSData).
{
    int         err;
    NSString *  result;
    char        hostStr[NI_MAXHOST];
    
    result = nil;
    
    if (address != nil) {
        err = getnameinfo([address bytes], (socklen_t) [address length], hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
        if (err == 0) {
            result = [NSString stringWithCString:hostStr encoding:NSASCIIStringEncoding];
            assert(result != nil);
        }
    }
    
    return result;
}

#pragma mark * Main

@interface Main : NSObject <SimplePingDelegate>

- (void)runWithHostName:(NSString *)hostName;

@end

@interface Main ()

@property (nonatomic, strong, readwrite) SimplePing *   pinger;
@property (nonatomic, strong, readwrite) NSTimer *      sendTimer;

@end

@implementation Main

@synthesize pinger    = _pinger;
@synthesize sendTimer = _sendTimer;

- (void)dealloc
{
    [self->_pinger stop];
    [self->_sendTimer invalidate];
}

- (NSString *)shortErrorFromError:(NSError *)error
// Given an NSError, returns a short error string that we can print, handling
// some special cases along the way.
{
    NSString *      result;
    NSNumber *      failureNum;
    int             failure;
    const char *    failureStr;
    
    assert(error != nil);
    
    result = nil;
    
    // Handle DNS errors as a special case.
    
    if ( [[error domain] isEqual:(NSString *)kCFErrorDomainCFNetwork] && ([error code] == kCFHostErrorUnknown) ) {
        failureNum = [[error userInfo] objectForKey:(id)kCFGetAddrInfoFailureKey];
        if ( [failureNum isKindOfClass:[NSNumber class]] ) {
            failure = [failureNum intValue];
            if (failure != 0) {
                failureStr = gai_strerror(failure);
                if (failureStr != NULL) {
                    result = [NSString stringWithUTF8String:failureStr];
                    assert(result != nil);
                }
            }
        }
    }
    
    // Otherwise try various properties of the error object.
    
    if (result == nil) {
        result = [error localizedFailureReason];
    }
    if (result == nil) {
        result = [error localizedDescription];
    }
    if (result == nil) {
        result = [error description];
    }
    assert(result != nil);
    return result;
}

- (void)runWithHostName:(NSString *)hostName
// The Objective-C 'main' for this program.  It creates a SimplePing object
// and runs the runloop sending pings and printing the results.
{
    assert(self.pinger == nil);
    
    self.pinger = [SimplePing simplePingWithHostName:hostName];
    assert(self.pinger != nil);
    
    self.pinger.delegate = self;
    [self.pinger start];
    
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
}

- (void)sendPing
// Called to send a ping, both directly (as soon as the SimplePing object starts up)
// and via a timer (to continue sending pings periodically).
{
    assert(self.pinger != nil);
    [self.pinger sendPingWithData:nil];
}

- (void)check
{
    NSLog(@"CHECKING....");
    NSLog(@"%fl", self.pinger.sentPings);
    NSLog(@"%fl", self.pinger.receivedPings);

}

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
// A SimplePing delegate callback method.  We respond to the startup by sending a
// ping immediately and starting a timer to continue sending them every second.
{
#pragma unused(pinger)
    assert(pinger == self.pinger);
    assert(address != nil);
    
    NSLog(@"pinging %@", DisplayAddressForAddress(address));
    
    // Send the first ping straight away.
    [self sendPing];
    
    // And start a timer to send the subsequent pings.
    // Get time interval for server
    float time;
    for (int i = 0; i < [list count]; i++) {
        ServerItem *element = [list objectAtIndex:i];
        if ([element isEqual:pinger.hostName]) {
            time = [element timeInterval];
        }
    }

    assert(self.sendTimer == nil);
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(sendPing) userInfo:nil repeats:YES];
    
    // Start checker
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(check) userInfo:nil repeats:YES];
    
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
// A SimplePing delegate callback method.  We shut down our timer and the
// SimplePing object itself, which causes the runloop code to exit.
{
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(error)
    NSLog(@"failed: %@", [self shortErrorFromError:error]);
    
    [self.sendTimer invalidate];
    self.sendTimer = nil;
    
    // No need to call -stop.  The pinger will stop itself in this case.
    // We do however want to nil out pinger so that the runloop stops.
    
    self.pinger = nil;
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the send.
{
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    test = 1;
    NSLog(@"#%u sent", (unsigned int) OSSwapBigToHostInt16(((const ICMPHeader *) [packet bytes])->sequenceNumber) );
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error
// A SimplePing delegate callback method.  We just log the failure.
{
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
#pragma unused(error)
    NSLog(@"#%u send failed: %@", (unsigned int) OSSwapBigToHostInt16(((const ICMPHeader *) [packet bytes])->sequenceNumber), [self shortErrorFromError:error]);
    [listItem setTitle:@"ZZZ"];
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the reception of a ping response.
{
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    NSLog(@"#%u received", (unsigned int) OSSwapBigToHostInt16([SimplePing icmpInPacket:packet]->sequenceNumber) );

    // Update item icon, state icon
    for (int i = 0; i < [list count]; i++) {
        ServerItem *element = [list objectAtIndex:i];
        if ([element isEqual:pinger.hostName]) {
            NSMenuItem *item = [element item];
            //[item setTitle: pinger.hostName];
            [item setImage:ok];
            [menuItem setImage:common];
        }
        
    }
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the receive.
{
    const ICMPHeader *  icmpPtr;
    
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    
    icmpPtr = [SimplePing icmpInPacket:packet];
    [listItem setTitle:@"ZZZ"];
    if (icmpPtr != NULL) {
        NSLog(@"#%u unexpected ICMP type=%u, code=%u, identifier=%u", (unsigned int) OSSwapBigToHostInt16(icmpPtr->sequenceNumber), (unsigned int) icmpPtr->type, (unsigned int) icmpPtr->code, (unsigned int) OSSwapBigToHostInt16(icmpPtr->identifier) );
    } else {
        NSLog(@"unexpected packet size=%zu", (size_t) [packet length]);
    }
}

@end


@implementation AppDelegate

@synthesize window;

- (void)awakeFromNib {
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    // Init images
    NSBundle *bundle = [NSBundle mainBundle];
    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"greenLight" ofType:@"png"]];
    common = statusImage;
    statusHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"redLight" ofType:@"png"]];
    highlight = statusHighlightImage;
    statusImageItem = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"signOk" ofType:@"png"]];
    ok = statusImageItem;
    
    [statusItem setImage:statusImage];
    //[statusItem setAlternateImage:statusImage];
    //Use a title instead of images
    //[statusItem setTitle:@"This text will appear instead of images"];
    [statusItem setMenu:statusMenu];
    [statusItem setToolTip:@"You do not need this..."];
    [statusItem setHighlightMode:NO];
    menuItem = statusItem;
    
    
    list = [[NSMutableArray alloc] init];
    ServerItem *item = [[ServerItem alloc] initWithAddress:@"google.ro"]; //1.0.0.0 to test nonworking functionality
    [list addObject:item];
    
    NSUserNotification *alert = [[NSUserNotification alloc] init];
    alert.title = @"sassasa";
    alert.informativeText = @"A notification";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:alert];

    // NSLog(@"%lf", [[NSDate date] timeIntervalSince1970]);
    
    for (int i = 0; i < [list count]; i++) {
        ServerItem *element = [list objectAtIndex:i];

        Main *mainObj;
        mainObj = [[Main alloc] init];
        assert(mainObj != nil);
        
        listItem = [[NSMenuItem alloc] initWithTitle:[element address] action:NULL keyEquivalent:@""];
        [listItem setImage:ok];
        [element setMenuItem:listItem];
        [statusMenu insertItem: listItem atIndex:i];
        
        [mainObj runWithHostName:[element address]];
    }
    
}

- (IBAction)doSomething:(id)sender {
    NSLog(@"aaaa");
}

@end
