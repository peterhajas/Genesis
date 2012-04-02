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

#import "GNTextView.h"

#define TEXT_INSET 5

@implementation GNTextView

@synthesize dataDelegate;

-(void)awakeFromNib
{
    // Inset the text
    [self setContentInset:UIEdgeInsetsMake(TEXT_INSET, TEXT_INSET, TEXT_INSET, TEXT_INSET)];
    innerView = [[GNTextInnerView alloc] init];
    [innerView setContainerDelegate:self];
    
    [self addSubview:innerView];
    
    [innerView fitFrameToText];
    CGSize sizeForTextview = [innerView frame].size;
    
    [self setContentSize:sizeForTextview];
    
    // Subscribe to keyboard notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];

}

-(void)requiresSize:(CGSize)size
{
    [self setContentSize:size];
}

-(BOOL)resignFirstResponder
{
    [innerView resignFirstResponder];
    return [super resignFirstResponder];
}

#pragma mark GNTextInnerViewContainerProtocol methods

-(void)requireSize:(CGSize)size
{
    [self setContentSize:size];
}

-(void)textChanged
{
    [dataDelegate textChanged];
}

#pragma mark Keyboard Notification Handling

-(void)keyboardWillChange:(id)object
{
    // Grab the dictionary out of the object
    
    NSDictionary* keyboardGeometry = [object userInfo];
    
    // Get the end frame rectangle of the keyboard
    
    NSValue* endFrameValue = [keyboardGeometry valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect endFrame = [endFrameValue CGRectValue];
    
    // Convert the rect into view coordinates from the window, this accounts for rotation
    
    UIWindow* appWindow = [[[UIApplication sharedApplication] delegate] window];
    
    CGRect keyboardFrame = [self convertRect:endFrame fromView:appWindow];
    
    // Our new view frame will have an origin of (0,0), a width the same as the keyboard,
    // and a height that goes until the keyboard starts (same as its y origin)
    
    CGRect newFrameForView = CGRectMake(0,
                                        0,
                                        keyboardFrame.size.width,
                                        keyboardFrame.origin.y);
    
    [self setFrame:newFrameForView];
}

#pragma mark Text Handling

-(void)setText:(NSString*)text
{
    [innerView setShownText:text];
}

-(NSString*)text
{
    return [innerView shownText];
}

@end
