//
//  AppDelegate.h
//  Purger
//
//  Created by Alexander Meiler on 29.12.12.
//  Copyright (c) 2012 Alexander Meiler. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
}

//@property (assign) IBOutlet NSWindow *window;
@property (nonatomic,assign) BOOL cleaning;
@property (nonatomic,assign) BOOL percent;
@property (weak) IBOutlet NSMenuItem *percentItem;
@property (weak) IBOutlet NSMenuItem *bootItem;

- (void)refreshTitle;

@end
