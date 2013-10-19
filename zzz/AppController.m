#import "AppController.h"
#import "WindowController.h"
#include "SimplePing.h"

#include <sys/socket.h>
#include <netdb.h>


@implementation AppController

- (IBAction)ping:(id)sender {
    NSLog(@"sasas");

}

- (IBAction)showPreferences:(id)sender {
    if (!winController) {
        winController = [[WindowController alloc] initWithWindowNibName:@"PreferencesWindow"];
    }
    [winController showWindow:self];
}

@end
