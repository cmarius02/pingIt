//
//  AppDelegate.h
//  zzz
//
//  Created by Marius Coțofană on 9/30/13.
//  Copyright (c) 2013 Marius Coțofană. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
    NSImage *statusImage;
    NSImage *statusHighlightImage;
    NSImage *statusImageItem;
}

- (IBAction)doSomething:(id)sender;

@property (assign) IBOutlet NSWindow *window;

@end
