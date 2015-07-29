//
//  AppDelegate.m
//  DisableOSXMouseAccel
//
//  Created by qii on 7/25/15.
//  Copyright (c) 2015 qii. All rights reserved.
//


#import "AppDelegate.h"
#import "LoginItem.h"
#include <IOKit/hidsystem/IOHIDLib.h>
#include <IOKit/hidsystem/IOHIDParameter.h>
#include <IOKit/hidsystem/event_status_driver.h>


static const NSString *MouseKey = @"mouse";
static const NSString *PadKey = @"pad";
static const NSString *AutoStartKey = @"autostart";

static const int32_t Default_Pad_Accelerate = 0xb000;
static const int32_t Default_Mouse_Accelerate = 0xe000;
static const int32_t Zero_Accelerate = -0x10000;

@interface AppDelegate ()
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSMenu *menu;
@property(nonatomic, strong) NSMenuItem *mouse;
@property(nonatomic, strong) NSMenuItem *pad;
@property(nonatomic, strong) NSMenuItem *autoStartMenu;

@property(nonatomic, strong) NSMutableDictionary *dictionary;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
//    _statusItem.title = @"M";
    _statusItem.highlightMode = YES;
    _statusItem.toolTip = @"DisableOSXMouseAccel";
    NSImage *statusImage = [NSImage imageNamed:@"mouse"];
    [_statusItem setImage:statusImage];

    _menu = [[NSMenu alloc] init];
    _mouse = [[NSMenuItem alloc] initWithTitle:@"Disable Mouse Accelerate" action:@selector(disableMouse) keyEquivalent:@""];
    [self.menu addItem:_mouse];
    _pad = [[NSMenuItem alloc] initWithTitle:@"Disable Trackpad Accelerate" action:@selector(disablePad) keyEquivalent:@""];
    [self.menu addItem:_pad];
    _autoStartMenu = [[NSMenuItem alloc] initWithTitle:@"Start When User Login" action:@selector(autoStart) keyEquivalent:@""];
    [self.menu addItem:_autoStartMenu];
    NSMenuItem *about = [[NSMenuItem alloc] initWithTitle:@"About" action:@selector(about) keyEquivalent:@""];
    [self.menu addItem:about];
    NSMenuItem *exit = [[NSMenuItem alloc] initWithTitle:@"Exit" action:@selector(itemClicked) keyEquivalent:@""];
    [self.menu addItem:exit];
    _statusItem.menu = _menu;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [defaults objectForKey:@"config"];
    self.dictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    BOOL disableMouse = ((NSNumber *) dictionary[MouseKey]).boolValue;
    BOOL disablePad = ((NSNumber *) dictionary[PadKey]).boolValue;
    BOOL autoStart = ((NSNumber *) dictionary[AutoStartKey]).boolValue;

    [self setAccelerate:disableMouse type:@"mouse"];
    [self setAccelerate:disablePad type:@"trackpad"];

    [_mouse setState:disableMouse ? NSOnState : NSOffState];
    [_pad setState:disablePad ? NSOnState : NSOffState];
    [_autoStartMenu setState:autoStart ? NSOnState : NSOffState];
//    int32_t defaultMouseAccel;
//    int32_t defaultPadAccel;
//    IOByteCount size = sizeof(defaultMouseAccel);
//    io_connect_t handle = NXOpenEventStatus();
//    if (handle) {
//        IOHIDGetParameter(handle, CFSTR(kIOHIDMouseAccelerationType), (IOByteCount) sizeof(defaultMouseAccel), &defaultMouseAccel, &size);
//        IOHIDGetParameter(handle, CFSTR(kIOHIDTrackpadAccelerationType), (IOByteCount) sizeof(defaultPadAccel), &defaultPadAccel, &size);
//        NXCloseEventStatus(handle);
//    }
}

- (void)disableMouse {
    BOOL disableMouse = ((NSNumber *) self.dictionary[MouseKey]).boolValue;
    [self setAccelerate:!disableMouse type:@"mouse"];
    self.dictionary[MouseKey] = @(!disableMouse);
    [[NSUserDefaults standardUserDefaults] setObject:self.dictionary forKey:@"config"];
    [_mouse setState:!disableMouse ? NSOnState : NSOffState];
}

- (void)disablePad {
    BOOL disablePad = ((NSNumber *) self.dictionary[PadKey]).boolValue;
    [self setAccelerate:!disablePad type:@"trackpad"];
    self.dictionary[PadKey] = @(!disablePad);
    [[NSUserDefaults standardUserDefaults] setObject:self.dictionary forKey:@"config"];
    [_pad setState:!disablePad ? NSOnState : NSOffState];
}

- (void)autoStart {
    BOOL autoStart = ((NSNumber *) self.dictionary[AutoStartKey]).boolValue;
    [self setStartAtLogin:!autoStart];
    self.dictionary[AutoStartKey] = @(!autoStart);
    [[NSUserDefaults standardUserDefaults] setObject:self.dictionary forKey:@"config"];
    [_autoStartMenu setState:!autoStart ? NSOnState : NSOffState];
}

- (void)about {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"About"];
    [alert setInformativeText:@"Author: qiibeta@gmail.com"];
    [alert setAlertStyle:NSInformationalAlertStyle];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
    }
}

//http://forums3.armagetronad.net/viewtopic.php?p=196564#p196564
- (void)setAccelerate:(BOOL)disable type:(NSString *)value {
    int32_t accel;
    io_connect_t handle = NXOpenEventStatus();
    if (handle) {
        int i;
        CFStringRef type = 0;
        if ([value isEqualToString:@"mouse"]) {
            type = CFSTR(kIOHIDMouseAccelerationType);
            accel = disable ? Zero_Accelerate : Default_Mouse_Accelerate;
        }
        else if ([value isEqualToString:@"trackpad"]) {
            type = CFSTR(kIOHIDTrackpadAccelerationType);
            accel = disable ? Zero_Accelerate : Default_Pad_Accelerate;
        }

        if (type && IOHIDSetParameter(handle, type, &accel, sizeof accel) != KERN_SUCCESS)
            fprintf(stderr, "Failed to kill %s accel\n", value.UTF8String);

        NXCloseEventStatus(handle);
    } else
        fprintf(stderr, "No handle\n");
}

- (void)itemClicked {
    [self setAccelerate:NO type:@"mouse"];
    [self setAccelerate:NO type:@"trackpad"];
    [[NSApplication sharedApplication] terminate:self];
}

- (NSURL *)appURL {
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL)startAtLogin {
    return [LoginItem willStartAtLogin:[self appURL]];
}

- (void)setStartAtLogin:(BOOL)enabled {
    [self willChangeValueForKey:@"startAtLogin"];
    [LoginItem setStartAtLogin:[self appURL] enabled:enabled];
    [self didChangeValueForKey:@"startAtLogin"];
}
@end