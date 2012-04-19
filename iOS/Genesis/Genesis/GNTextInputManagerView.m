/* Copyright (c) 2012, individual contributors
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#import "GNTextInputManagerView.h"
#import "GNTextGeometry.h"
#import "GNLineNumberTableView.h"
#import "GNTextAlternateInputView.h"
#import "GNFileRepresentation.h"

@implementation GNTextInputManagerView

@synthesize delegate;
@synthesize inputView;
@synthesize inputAccessoryView;

-(id)initWithFileRepresentation:(GNFileRepresentation*)representation
{
    self = [super init];
    if(self)
    {
        fileRepresentation = representation;
        
        // Subscribe to insertion point changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(insertionPointChanged:)
                                                     name:GNInsertionPointChangedNotification
                                                   object:nil];
        
        // Subscribe to keyboard command changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dismissKeyboard)
                                                     name:GNDismissKeyboardNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(switchToAutocompleteKeyboard)
                                                     name:GNSwitchToAutoCompleteKeyboardNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(switchToSystemKeyboard)
                                                     name:GNSwitchToSystemKeyboardNotification
                                                   object:nil];
        
        // (hacky) Subscribe to replacement notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(replaceCurrentWord:)
                                                     name:GNReplaceCurrentWordNotification
                                                   object:nil];
        
        
        
        caretView = [[GNTextCaretView alloc] init];
        [self addSubview:caretView];
        
        // Set our autoresizing mask
        [self setAutoresizingMask:(UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleHeight)];
        
        // Set our input accessory view
        inputAccessoryView = [[GNTextInputAccessoryView alloc] init];
        [self setInputAccessoryView:inputAccessoryView];
    }
    return self;
}

-(void)insertionPointChanged:(NSNotification*)notification
{
    NSUInteger insertionLine = [[fileRepresentation insertionPointManager] insertionLine];
    NSUInteger insertionIndexInLine = [[fileRepresentation insertionPointManager] insertionIndexInLine];
    
    CGFloat lineHeight = [GNTextGeometry lineHeight];
    
    NSString* lineToInsertionIndex = [[fileRepresentation fileText] lineToInsertionPoint];
    CGSize sizeOfLineToInsertionIndex = [lineToInsertionIndex sizeWithFont:[GNTextGeometry defaultUIFont]];    
    
    CGFloat newCaretViewXLocation = sizeOfLineToInsertionIndex.width + kGNLineNumberTableViewWidth;
    
    if(insertionIndexInLine != 0)
    {
        [caretView setFrame:CGRectMake(newCaretViewXLocation,
                                       lineHeight * insertionLine,
                                       kGNTextCaretViewWidth,
                                       lineHeight)];
    }
    else
    {
        [caretView setHorizontalOffset:0.0];
        [caretView setFrame:CGRectMake(newCaretViewXLocation,
                                       lineHeight * insertionLine,
                                       kGNTextCaretViewWidth,
                                       lineHeight)];
    }
        
    [self becomeFirstResponder];
    [self toggleMinimalView:YES];
}

-(void)didScrollToVerticalOffset:(CGFloat)offset
{
    [caretView setVerticalOffset:offset];
}

#pragma mark UITextInputTraits methods

-(UITextAutocapitalizationType)autocapitalizationType
{
    return UITextAutocapitalizationTypeNone;
}

-(UITextAutocorrectionType)autocorrectionType
{
    return UITextAutocorrectionTypeNo;
}

-(BOOL)enablesReturnKeyAutomatically
{
    return YES;
}

-(UIKeyboardAppearance)keyboardAppearance
{
    return UIKeyboardAppearanceDefault;
}

-(UIKeyboardType)keyboardType
{
    return UIKeyboardTypeDefault;
}

-(UIReturnKeyType)returnKeyType
{
    return UIReturnKeyDefault;
}

-(BOOL)isSecureTextEntry
{
    return NO;
}

#pragma mark UIKeyInput methods

-(BOOL)hasText
{
    return [[fileRepresentation fileText] hasText];
}

-(void)insertText:(NSString *)text
{
    [[fileRepresentation fileText] insertText:text];
}

-(void)deleteBackward
{
    [[fileRepresentation fileText] deleteBackwards];
}

-(void)toggleMinimalView:(BOOL)toggle
{
    // Show the status bar and navigation bar
    [[UIApplication sharedApplication] setStatusBarHidden:toggle withAnimation:UIStatusBarAnimationSlide];
    [[NSNotificationCenter defaultCenter] postNotificationName:GNToggleNavigationBarNotification
                                                        object:[NSNumber numberWithBool:toggle]];
}

-(void)replaceCurrentWord:(id)object
{
    NSString* toReplace = [object object];
    [self replaceTextInRange:[[fileRepresentation fileText] rangeOfCurrentWord] withText:toReplace];
}

#pragma mark UIResponder methods

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(BOOL)becomeFirstResponder
{
    [caretView setHidden:NO];
    return [super becomeFirstResponder];
}

-(void)dismissKeyboard
{
    [self resignFirstResponder];
    [self toggleMinimalView:NO];
    [caretView setHidden:YES];
}

-(void)switchToAutocompleteKeyboard;
{
    alternateInputView = [[GNTextAutocompleteInputView alloc] initWithDelegate:self
                                                         andFileRepresentation:fileRepresentation];
    [self resignFirstResponder];
    [self setInputView:alternateInputView];
    [self becomeFirstResponder];
}

-(void)switchToSystemKeyboard
{
    alternateInputView = nil;
    [self resignFirstResponder];
    [self setInputView:nil];
    [self becomeFirstResponder];
}

#pragma mark GNTextAlternateInputViewDelegate methods

-(void)insertText:(NSString*)text indexDelta:(NSInteger)indexDelta
{
    [[fileRepresentation fileText] insertText:text indexDelta:indexDelta];
}

-(void)replaceTextInRange:(NSRange)range withText:(NSString*)text
{
    [[fileRepresentation fileText] replaceTextInRange:range withText:text];
}

#pragma mark Lifecycle cleanup methods

-(void)cleanUp
{
    [caretView cleanUp];
    [caretView removeFromSuperview];
    alternateInputView = nil;
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
