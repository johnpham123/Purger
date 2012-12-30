//
//  AppDelegate.m
//  Purger
//
//  Created by Alexander Meiler on 29.12.12.
//  Copyright (c) 2012 Alexander Meiler. All rights reserved.
//

#import <sys/sysctl.h>
#import <sys/types.h>
#import <mach/vm_statistics.h>
#import <mach/mach_types.h>
#import <mach/mach_init.h>
#import <mach/mach_host.h>

#import "AppDelegate.h"
#import "LaunchAtLoginController.h"

@implementation AppDelegate

@synthesize cleaning,percent,percentItem,bootItem;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"firstTime"] == NULL) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"percent"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"startAtBoot"];
        [[NSUserDefaults standardUserDefaults] setValue:@"Not" forKey:@"firstTime"];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.percent = [defaults boolForKey:@"percent"];
    BOOL startAtBoot = [defaults boolForKey:@"startAtBoot"];
    [percentItem setState:self.percent];
    [bootItem setState:startAtBoot];
    // Insert code here to initialize your application
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(refreshTitle)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)refreshTitle {
    if(self.cleaning == NO && self.percent == YES) {
        int mib[2];
        int64_t physical_memory;
        mib[0] = CTL_HW;
        mib[1] = HW_MEMSIZE;
        size_t length = sizeof(int64_t);
        sysctl(mib, 2, &physical_memory, &length, NULL, 0);
        
        vm_size_t page_size;
        mach_port_t mach_port;
        mach_msg_type_number_t count;
        vm_statistics_data_t vm_stats;
        mach_port = mach_host_self();
        count = sizeof(vm_stats) / sizeof(natural_t);
        if (KERN_SUCCESS == host_page_size(mach_port, &page_size) &&
            KERN_SUCCESS == host_statistics(mach_port, HOST_VM_INFO,
                                            (host_info_t)&vm_stats, &count))
        {       
            int64_t used_memory = ((int64_t)vm_stats.active_count +
                           (int64_t)vm_stats.inactive_count +
                           (int64_t)vm_stats.wire_count) *  (int64_t)page_size;
            int percent = ((float)used_memory / (float)physical_memory) *100;
            NSString *title = [NSString stringWithFormat:@"Purger (%i%%)",percent];
            [statusItem setTitle:title];
        } else {
            [statusItem setTitle:@"Purger (?%%)"];
        }
    }
}

-(void)awakeFromNib{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:@"Purger"];
    [self refreshTitle];
    [statusItem setHighlightMode:YES];
}

- (IBAction)freeUp:(NSMenuItem *)sender {
    NSTask* task = [NSTask new];
    [task setLaunchPath:@"/usr/bin/purge"];
    [task launch];
    self.cleaning = YES;
    sender.enabled = NO;
    [statusItem setTitle:@"Purger (cleaning..)"];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSTaskDidTerminateNotification
                                                      object:task
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notif){
                                                      self.cleaning = NO;
                                                      sender.enabled = YES;
                                                      [self refreshTitle];
    }];
}

- (IBAction)percentClicked:(NSMenuItem *)sender {
    [statusItem setTitle:@"Purger"];
    self.percent = !self.percent;
    [sender setState:self.percent];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL percent = sender.state;
    [defaults setBool:percent forKey:@"percent"];
    [defaults synchronize];
}

- (IBAction)bootClicked:(NSMenuItem *)sender {
    sender.state = !sender.state;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL boot = sender.state;
    [defaults setBool:boot forKey:@"startAtBoot"];
    [defaults synchronize];
    
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    [launchController setLaunchAtLogin:boot];
}

- (IBAction)showInfo:(NSMenuItem *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setInformativeText:@"Version 1.0.0"];
    [alert setMessageText:@"This tool was developed by Alexander Meiler (c) 2012.\nSource available at github.com/rootd/Purger"];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert runModal];
}

- (IBAction)exit:(id)sender {
    exit(0);
}


@end
