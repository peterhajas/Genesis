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

#import "GNTextInputAccessoryView.h"
#import "GNTextAlternateInputView.h"

@implementation GNTextInputAccessoryView

-(id)init
{
    self = [super initWithFrame:CGRectMake(0,
                                           0,
                                           [[UIScreen mainScreen] bounds].size.width,
                                           kGNTextInputAccessoryViewHeight)];
    if(self)
    {
        // Set our autoresize mask
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        // Create our gradient layer
        gradientLayer = [self gradientLayer];
        [[self layer] addSublayer:gradientLayer];
        
        // Set up our buttons
        
        // Tab button
        tabButton = [[GNTextInputAccessoryViewTabButton alloc] init];
        [tabButton setHorizontalPosition:0];
        [tabButton addTarget:self action:@selector(tabPushed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:tabButton];
        
        // Auto complete button
        autoCompleteButton = [[GNTextInputAccessoryViewAutocompleteButton alloc] init];
        [autoCompleteButton setHorizontalPosition:kGNTextInputAccessoryViewButtonWidth];
        [self addSubview:autoCompleteButton];
        
        // Hide keyboard button
        hideKeyboardButton = [[GNTextInputAccessoryViewHideKeyboardButton alloc] init];
        [hideKeyboardButton setHorizontalPosition:[self frame].size.width - kGNTextInputAccessoryViewButtonWidth];
        [hideKeyboardButton addTarget:self action:@selector(hideKeyboard) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:hideKeyboardButton];
    }
    
    return self;
}

-(void)layoutSubviews
{
    [gradientLayer setFrame:[self frame]];
}

-(void)didMoveToSuperview
{
    [autoCompleteButton registerForNotifications];
}

-(void)tabPushed
{
    [[NSNotificationCenter defaultCenter] postNotificationName:GNInsertTabAtInsertionPointNotification object:nil];
}

-(void)hideKeyboard
{
    [[NSNotificationCenter defaultCenter] postNotificationName:GNDismissKeyboardNotification object:nil];
}

-(CAGradientLayer*)gradientLayer
{
    CAGradientLayer* layer = [CAGradientLayer layer];
    [layer setColors:kGNTextInputAccessoryGradientColors];
    [layer setFrame:[self frame]];
    return layer;
}

-(void)removeFromSuperview
{
    [super removeFromSuperview];
    [autoCompleteButton cleanUp];
}

@end
