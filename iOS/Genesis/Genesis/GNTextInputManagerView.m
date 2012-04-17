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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(insertionPointChanged:)
                                                     name:@"kGNInsertionPointChanged"
                                                   object:nil];
        caretView = [[GNTextCaretView alloc] init];
        [self addSubview:caretView];
        
        // Set our autoresizing mask
        [self setAutoresizingMask:(UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleHeight)];
        
        // Set our input accessory view
        inputAccessoryView = [[GNTextInputAccessoryView alloc] initWithDelegate:self];
        [self setInputAccessoryView:inputAccessoryView];
    }
    return self;
}

-(void)insertionPointChanged:(NSNotification*)notification
{
    NSUInteger insertionLine = [fileRepresentation insertionLine];
    
    CGFloat lineHeight = [GNTextGeometry lineHeight];
    
    NSString* lineToInsertionIndex = [fileRepresentation lineToInsertionPoint];
    CGSize sizeOfLineToInsertionIndex = [lineToInsertionIndex sizeWithFont:[GNTextGeometry defaultUIFont]];    
    
    CGFloat newCaretViewXLocation = sizeOfLineToInsertionIndex.width + kGNLineNumberTableViewWidth;
    
    [caretView setFrame:CGRectMake(newCaretViewXLocation,
                                   lineHeight * insertionLine,
                                   kGNTextCaretViewWidth,
                                   lineHeight)];
        
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
    return [fileRepresentation hasText];
}

-(void)insertText:(NSString *)text
{
    [fileRepresentation insertText:text];
}

-(void)deleteBackward
{
    [fileRepresentation deleteBackwards];
}

-(void)toggleMinimalView:(BOOL)toggle
{
    // Show the status bar and navigation bar
    [[UIApplication sharedApplication] setStatusBarHidden:toggle withAnimation:UIStatusBarAnimationSlide];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kGNToggleNavigationBar"
                                                        object:[NSNumber numberWithBool:toggle]];
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

#pragma mark GNTextInputAccessoryViewDelegate methods
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
    [self setInputView:nil];
}

#pragma mark GNTextAlternateInputViewDelegate methods

-(void)insertText:(NSString*)text indexDelta:(NSInteger)indexDelta
{
    
}

-(void)replaceTextInRange:(NSRange)range withText:(NSString*)text
{
    
}

#pragma mark Lifecycle cleanup methods

-(void)cleanUp
{
    [caretView cleanUp];
    [caretView removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
