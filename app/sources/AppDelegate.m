//
//  AppDelegate.m
//  HexFiend_2
//
//  Created by Peter Ammon on 4/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "MyDocument.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)note {
    USE(note);
    [NSThread detachNewThreadSelector:@selector(buildFontMenu:) toTarget:self withObject:nil];
    [extendForwardsItem setKeyEquivalentModifierMask:[extendForwardsItem keyEquivalentModifierMask] | NSShiftKeyMask];
    [extendBackwardsItem setKeyEquivalentModifierMask:[extendBackwardsItem keyEquivalentModifierMask] | NSShiftKeyMask];
    [extendForwardsItem setKeyEquivalent:@"]"];
    [extendBackwardsItem setKeyEquivalent:@"["];
}

static NSComparisonResult compareFontDisplayNames(NSFont *a, NSFont *b, void *unused) {
    USE(unused);
    return [[a displayName] caseInsensitiveCompare:[b displayName]];
}

- (void)buildFontMenu:unused {
    USE(unused);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSFontManager *manager = [NSFontManager sharedFontManager];
    NSCharacterSet *minimumRequiredCharacterSet;
    NSMutableCharacterSet *minimumCharacterSetMutable = [[NSMutableCharacterSet alloc] init];
    [minimumCharacterSetMutable addCharactersInRange:NSMakeRange('0', 10)];
    [minimumCharacterSetMutable addCharactersInRange:NSMakeRange('a', 26)];
    [minimumCharacterSetMutable addCharactersInRange:NSMakeRange('A', 26)];
    minimumRequiredCharacterSet = [[minimumCharacterSetMutable copy] autorelease];
    [minimumCharacterSetMutable release];
    
    NSMutableSet *fontNames = [NSMutableSet setWithArray:[manager availableFontNamesWithTraits:NSFixedPitchFontMask]];
    [fontNames minusSet:[NSSet setWithArray:[manager availableFontNamesWithTraits:NSFixedPitchFontMask | NSBoldFontMask]]];
    [fontNames minusSet:[NSSet setWithArray:[manager availableFontNamesWithTraits:NSFixedPitchFontMask | NSItalicFontMask]]];
    NSMutableArray *fonts = [NSMutableArray arrayWithCapacity:[fontNames count]];
    FOREACH(NSString *, fontName, fontNames) {
        NSFont *font = [NSFont fontWithName:fontName size:0];
        NSString *displayName = [font displayName];
        if (! [displayName length]) continue;
        unichar firstChar = [displayName characterAtIndex:0];
        if (firstChar == '#' || firstChar == '.') continue;
        if (! [[font coveredCharacterSet] isSupersetOfSet:minimumRequiredCharacterSet]) continue; //weed out some useless fonts, like Monotype Sorts
        [fonts addObject:font];
    }
    [fonts sortUsingFunction:compareFontDisplayNames context:NULL];
    [self performSelectorOnMainThread:@selector(receiveFonts:) withObject:fonts waitUntilDone:NO modes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];
    [pool release];
}

- (void)receiveFonts:(NSArray *)fonts {
    NSMenu *menu = [fontMenuItem submenu];
    [menu removeItemAtIndex:0];
    NSUInteger itemIndex = 0;
    FOREACH(NSFont *, font, fonts) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[font displayName] action:@selector(setFontFromMenuItem:) keyEquivalent:@""];
        [item setRepresentedObject:font];
        [item setTarget:self];
        [menu insertItem:item atIndex:itemIndex++];
        /* Validate the menu item in case the menu is currently open, so it gets the right check */
        [self validateMenuItem:item];
        [item release];
    }
}

- (void)setFontFromMenuItem:(NSMenuItem *)item {
    NSFont *font = [item representedObject];
    HFASSERT([font isKindOfClass:[NSFont class]]);
    MyDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
    [document setFont:font];
}


- (BOOL)validateMenuItem:(NSMenuItem *)item {
    SEL sel = [item action];
    if (sel == @selector(setFontFromMenuItem:)) {
        MyDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
        BOOL check = NO;
        if (document) {
            NSFont *font = [document font];
            check = [[item title] isEqualToString:[font displayName]];
        }
        [item setState:check];
        return document != nil;
    }
    return YES;
}

@end