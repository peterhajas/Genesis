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

@implementation GNTextInputManagerView

@synthesize delegate;
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
        inputAccessoryView = [[GNTextInputAccessoryView alloc] initWithDelegate:nil];
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

#pragma mark UIResponder methods

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark Lifecycle cleanup methods

-(void)cleanUp
{
    [caretView cleanUp];
    [inputAccessoryView cleanUp];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
