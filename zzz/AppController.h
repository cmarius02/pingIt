//
//  AppController.h
//  zzz
//
//  Created by Marius Coțofană on 9/30/13.
//  Copyright (c) 2013 Marius Coțofană. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WindowController;

@interface AppController : NSObject {
    IBOutlet NSTextField *label;
    WindowController *winController;
}

- (IBAction)ping:(id)sender;
- (IBAction)showPreferences:(id)sender;

@end
