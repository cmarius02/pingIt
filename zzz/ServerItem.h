#import <Foundation/Foundation.h>

@interface ServerItem : NSObject {
    NSString *address;
    NSMenuItem *menuItem;
    
    float time;
}

- (id) initWithAddress:(NSString *)theAddress;
- (BOOL)isEqual:(NSString *)theName;
- (void)setAddress:(NSString *)source;
- (void)setMenuItem:(NSMenuItem *)theItem;

- (NSString *)address;
- (NSMenuItem *)item;
- (float)timeInterval;


@end
