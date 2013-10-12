#import "ServerItem.h"

@implementation ServerItem

- (id)initWithAddress:(NSString *)theAddress {
    self = [super init];
    if (self) {
        self.address = theAddress;
        self->time = 5.0;
    }
    
    return self;
}

- (BOOL)isEqual:(NSString *)theName {
    if ([address isEqualToString:theName]) {
        return YES;
    }
    return NO;
}

- (void)setAddress:(NSString *)source {
    address = source;
}

- (void)setMenuItem:(NSMenuItem *)theItem {
    menuItem = theItem;
}


- (NSString *)address {
    return address;
}

- (NSMenuItem *)item {
    return menuItem;
}

- (float)timeInterval {
    return time;
}


@end
