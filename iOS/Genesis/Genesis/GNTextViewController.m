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

#import "GNTextViewController.h"
#import "GNFileRepresentation.h"

@implementation GNTextViewController

-(id)initWithBackingPath:(NSString*)path;
{
    self = [super initWithNibName:@"GNTextViewController" bundle:[NSBundle mainBundle]];
    if(self)
    {
        backingPath = path;
        [self setTitle:[backingPath lastPathComponent]];
        
        // Subscribe to keyboard notifications
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardChanged:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardChanged:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        // Subscribe to navigation bar hiding notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(toggleNavigationBar:)
                                                     name:GNToggleNavigationBarNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark View lifecycle

-(void)viewWillAppear:(BOOL)animated
{
    // Create text view
    textView = [[GNTextView alloc] initWithBackingPath:backingPath andFrame:[textViewContainerView frame]];
    [textViewContainerView addSubview:textView];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [textView cleanUp];
}

#pragma mark Keyboard Notification Handling

-(void)keyboardChanged:(id)object
{
    // Grab the dictionary out of the object
    
    NSDictionary* keyboardGeometry = [object userInfo];
    
    // Get the end frame rectangle of the keyboard
    
    NSValue* endFrameValue = [keyboardGeometry valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect endFrame = [endFrameValue CGRectValue];
    
    // Convert the rect into view coordinates from the window, this accounts for rotation
    
    UIWindow* appWindow = [[[UIApplication sharedApplication] delegate] window];
    
    CGRect keyboardFrame = [[self view] convertRect:endFrame fromView:appWindow];
    
    // Our new view frame will have an origin of (0,0), a width the same as the keyboard,
    // and a height that goes until the keyboard starts (same as its y origin)
    
    CGRect newFrameForView = CGRectMake(0,
                                        0,
                                        keyboardFrame.size.width,
                                        keyboardFrame.origin.y);
    
    [[self view] setFrame:newFrameForView];
    [textView setFrame:newFrameForView];
}

#pragma mark Navigation bar Notification Handling

-(void)toggleNavigationBar:(id)object
{
    BOOL shouldBeHidden = [[object object] boolValue];
    [[self navigationController] setNavigationBarHidden:shouldBeHidden animated:YES];
}

#pragma mark Orientation changes

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

@end
