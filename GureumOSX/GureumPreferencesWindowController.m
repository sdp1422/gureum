//
//  GureumPreferences.m
//  CharmIM
//
//  Created by youknowone on 11. 9. 22..
//  Copyright 2011 youknowone.org. All rights reserved.
//

#import <ShortcutRecorder/ShortcutRecorder.h>

#import "GureumPreferencesWindowController.h"

#import "CIMConfiguration.h"
#import "HangulComposer.h"

#define DEBUG_PREFERENCE TRUE

@interface GureumPreferencesWindowController ()

- (void)loadFromConfiguration;
- (void)showPreferenceViewWithIdentifier:(id)identifier animate:(BOOL)animate;

@end

static NSArray *GureumPreferencesHangulLayouts = nil;
static NSArray *GureumPreferencesHangulLayoutLocalizedNames = nil;
static NSArray *GureumPreferencesHangulSyllablePresentations = nil;

@implementation GureumPreferencesWindowController

+ (void)initialize {
    [super initialize];
    GureumPreferencesHangulLayouts = [[NSArray alloc] initWithObjects:
                     @"org.youknowone.inputmethod.GureumKIM.han2",
                     @"org.youknowone.inputmethod.GureumKIM.han2classic",
                     @"org.youknowone.inputmethod.GureumKIM.han3final",
                     @"org.youknowone.inputmethod.GureumKIM.han3finalloose",
                     @"org.youknowone.inputmethod.GureumKIM.han390",
                     @"org.youknowone.inputmethod.GureumKIM.han390loose",
                     @"org.youknowone.inputmethod.GureumKIM.han3noshift",
                     @"org.youknowone.inputmethod.GureumKIM.han3classic",
                     //@"org.youknowone.inputmethod.GureumKIM.han3layout2",
                     @"org.youknowone.inputmethod.GureumKIM.hanroman",
                     @"org.youknowone.inputmethod.GureumKIM.hanahnmatae",
                     @"org.youknowone.inputmethod.GureumKIM.han3-2011",
                     @"org.youknowone.inputmethod.GureumKIM.han3-2011loose",
                     @"org.youknowone.inputmethod.GureumKIM.han3-2012",
                     @"org.youknowone.inputmethod.GureumKIM.han3-2012loose",
                     @"org.youknowone.inputmethod.GureumKIM.han3finalnoshift",
                     nil];

    NSDictionary *info = [[NSBundle mainBundle] localizedInfoDictionary];
    NSMutableArray *names = [NSMutableArray array];
    for (NSString *layout in GureumPreferencesHangulLayouts) {
        [names addObject:info[layout]];
    }
    GureumPreferencesHangulLayoutLocalizedNames = [[NSArray alloc] initWithArray:names];
    
    GureumPreferencesHangulSyllablePresentations = [[NSArray alloc] initWithObjects:
                                                    NSLocalizedStringFromTable(@"HangulPresentationRemoveFillers", @"Hangul", @""),
                                                    NSLocalizedStringFromTable(@"HangulPresentationAllFillers", @"Hangul", @""),
                                                    NSLocalizedStringFromTable(@"HangulPresentationRemoveNonJungseongFiller", @"Hangul", @""),
                                                    NSLocalizedStringFromTable(@"HangulPresentationHideFromFiller", @"Hangul", @""),
                                                    NSLocalizedStringFromTable(@"HangulPresentationHideFromJungseongFiller", @"Hangul", @""),
                                                    nil];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self->preferenceViews = [[NSDictionary alloc] initWithObjectsAndKeys:
                       gureumPreferenceView, @"Gureum",
                       hangulPreferenceView, @"Hangul",
                       nil];

    [self loadFromConfiguration];
    [self showPreferenceViewWithIdentifier:@"Gureum" animate:YES];
}

- (void)dealloc
{
    [self->preferenceViews release];
    [super dealloc];
}

#pragma mark -

- (void)selectPreferenceItem:(NSToolbarItem *)sender {
    NSString *identifier = [sender itemIdentifier];
    dlog(DEBUG_PREFERENCE, @"preference identifier: %@", identifier);
    [self showPreferenceViewWithIdentifier:identifier animate:YES];
}

#pragma mark NSToolbar delegate

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    return YES;
}

#pragma mark - private

- (void)showPreferenceViewWithIdentifier:(id)identifier animate:(BOOL)animate {
    NSView *newPreferenceView = self->preferenceViews[identifier];
    if (newPreferenceView == nil) return;
    
    NSArray *preferenceSubviews = self->preferenceContainerView.subviews;
    NSView *oldPreferenceView = [preferenceSubviews count] > 0 ? preferenceSubviews[0] : nil;
    
    // Remove old one
    if (oldPreferenceView == newPreferenceView) return;
    [oldPreferenceView removeFromSuperview];
    
    // Arrange
    CGFloat toolbarHeight = NSHeight(self.window.frame) - NSHeight([self.window.contentView frame]);
    
    NSRect containerRect = preferenceContainerView.frame;
    containerRect.size = newPreferenceView.frame.size;
    
    NSRect windowFrame = self.window.frame;
    windowFrame.size = containerRect.size;
    windowFrame.size.height += toolbarHeight;
    windowFrame.size.height += commonButtonsView.frame.size.height;
    CGFloat heightDiff = windowFrame.size.height - self.window.frame.size.height;
    windowFrame.origin.y -= heightDiff; // keep origin y
    [self.window setFrame:windowFrame display:YES animate:animate];
    
    self->preferenceContainerView.frame = containerRect;
    
    // Add new one
    [self->preferenceContainerView addSubview:newPreferenceView];
}

- (void)loadFromConfiguration {
    CIMConfiguration *configuration = [CIMConfiguration userDefaultConfiguration];

    // common
    self->inputModeExchangeKeyRecorderCell.keyCombo = SRMakeKeyCombo(configuration->inputModeExchangeKeyCode, configuration->inputModeExchangeKeyModifier);
    NSLog(@"default input mode: %d", configuration->autosaveDefaultInputMode);
    self->autosaveDefaultInputModeCheckbox.integerValue = configuration->autosaveDefaultInputMode;
    NSLog(@"last hangul input mode: %@", configuration->lastHangulInputMode);
    NSInteger index = [GureumPreferencesHangulLayouts indexOfObject:configuration->lastHangulInputMode];
    self->defaultHangulInputModeComboBox.stringValue = GureumPreferencesHangulLayoutLocalizedNames[index];
    self->romanModeByEscapeKeyCheckbox.integerValue = configuration->romanModeByEscapeKey;
    self->zeroWidthSpaceForLayoutExchangeCheckbox.integerValue = configuration->zeroWidthSpaceForLayoutExchange;

    // hangul
    self->inputModeHanjaKeyRecorderCell.keyCombo = SRMakeKeyCombo(configuration->inputModeHanjaKeyCode, configuration->inputModeHanjaKeyModifier);
    [self->optionKeyBehaviorComboBox selectItemAtIndex:configuration->optionKeyBehavior];
    if (!(0 <= configuration->hangulCombinationModeComposing && configuration->hangulCombinationModeComposing < HangulCharacterCombinationModeCount)) {
        configuration->hangulCombinationModeComposing = 0;
    }
    self->showsInputForHanjaCandidatesCheckbox.integerValue = configuration->showsInputForHanjaCandidates;

    self->hangulCombinationModeComposingComboBox.stringValue = GureumPreferencesHangulSyllablePresentations[configuration->hangulCombinationModeComposing];
    if (!(0 <= configuration->hangulCombinationModeCommiting && configuration->hangulCombinationModeCommiting < HangulCharacterCombinationModeCount)) {
        configuration->hangulCombinationModeCommiting = 0;
    }
    self->hangulCombinationModeCommitingComboBox.stringValue = GureumPreferencesHangulSyllablePresentations[configuration->hangulCombinationModeCommiting];

    self->zeroWidthSpaceForBlankComposedStringCheckbox.integerValue = configuration->zeroWidthSpaceForBlankComposedString;
}

- (void)saveToConfiguration:(id)sender {
    CIMConfiguration *configuration = [CIMConfiguration userDefaultConfiguration];

    // common
    configuration->inputModeExchangeKeyCode = self->inputModeExchangeKeyRecorderCell.keyCombo.code;
    configuration->inputModeExchangeKeyModifier = self->inputModeExchangeKeyRecorderCell.keyCombo.flags;
    configuration->autosaveDefaultInputMode = self->autosaveDefaultInputModeCheckbox.integerValue;
    NSInteger index = [GureumPreferencesHangulLayoutLocalizedNames indexOfObject:self->defaultHangulInputModeComboBox.stringValue];
    configuration->lastHangulInputMode = GureumPreferencesHangulLayouts[index];
    configuration->optionKeyBehavior = [self->optionKeyBehaviorComboBox indexOfSelectedItem];
    configuration->romanModeByEscapeKey = self->romanModeByEscapeKeyCheckbox.integerValue;
    configuration->zeroWidthSpaceForLayoutExchange = self->zeroWidthSpaceForLayoutExchangeCheckbox.integerValue;

    // hangeul
    configuration->inputModeHanjaKeyCode = self->inputModeHanjaKeyRecorderCell.keyCombo.code;
    configuration->inputModeHanjaKeyModifier = self->inputModeHanjaKeyRecorderCell.keyCombo.flags;
    configuration->showsInputForHanjaCandidates = self->showsInputForHanjaCandidatesCheckbox.integerValue;
    configuration->hangulCombinationModeComposing = [GureumPreferencesHangulSyllablePresentations indexOfObject:self->hangulCombinationModeComposingComboBox.stringValue];
    configuration->hangulCombinationModeCommiting = [GureumPreferencesHangulSyllablePresentations indexOfObject:self->hangulCombinationModeCommitingComboBox.stringValue];

    configuration->zeroWidthSpaceForBlankComposedString = self->zeroWidthSpaceForBlankComposedStringCheckbox.integerValue;

    [configuration saveAllConfigurations];
}

- (void)cancelAndClose:(id)sender {
    self->cancel = YES;
    [self.window close];
}

- (void)helpChangeShortcut:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"도움말" defaultButton:@"확인" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Space 또는 ⇧Space 로 초기화하고 새로 설정할 수 있습니다."];
    [alert beginSheetModalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

#pragma NSWindow delegate

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"notification: %@", notification);
    if (!self->cancel) {
        [self saveToConfiguration:nil];
    }
    self->cancel = NO;
}

#pragma NSComboBox dataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return [GureumPreferencesHangulLayouts count];
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)string {
    return [GureumPreferencesHangulLayoutLocalizedNames indexOfObject:string];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    if (aComboBox == defaultHangulInputModeComboBox) {
        return GureumPreferencesHangulLayoutLocalizedNames[index];
    }
    if (aComboBox == hangulCombinationModeComposingComboBox || aComboBox == hangulCombinationModeCommitingComboBox) {
        return GureumPreferencesHangulSyllablePresentations[index];
    }
    assert(NO);
    return nil;
}

@end
