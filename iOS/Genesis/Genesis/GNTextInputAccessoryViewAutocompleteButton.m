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

#import "GNTextInputAccessoryViewAutocompleteButton.h"
#import "GNFileRepresentation.h"

@implementation GNTextInputAccessoryViewAutocompleteButton

-(id)init
{
    self = [super init];
    if(self)
    {
        // Create our swipe gesture recognizers
        swipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(didSwipeDown:)];
        [swipeDownGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];
        [self addGestureRecognizer:swipeDownGestureRecognizer];
        
        swipeUpGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(didSwipeUp:)];
        [swipeUpGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionUp];
        [self addGestureRecognizer:swipeUpGestureRecognizer];
    }
    return self;
}

-(void)didMoveToSuperview
{
    // Subscribe to the text changed notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textChanged:)
                                                 name:@"kGNTextChanged"
                                               object:nil];
}

-(void)didSwipeDown:(UIGestureRecognizer*)gestureRecognizer
{
    // Switch to the autocomplete keyboard
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kGNAutocompleteKeyboard" object:nil];
}

-(void)didSwipeUp:(UIGestureRecognizer*)gestureRecognizer
{
    // Switch to the system keyboard
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kGNSystemKeyboard" object:nil];
}

-(void)textChanged:(id)object
{
    GNFileRepresentation* fileRepresentation = [object object];
    
    NSString* currentWord = [fileRepresentation currentWord];
    
    NSArray* autocorrectionSuggestions = [[fileRepresentation autoCompleteDictionary] orderedMatchesForText:currentWord];
        
    // Set our title to the top autocorrection match
    if([autocorrectionSuggestions count] > 0)
    {
        NSString* firstMatch = [autocorrectionSuggestions objectAtIndex:0];
        [self setTitle:firstMatch
              forState:UIControlStateNormal];
    }
    else
    {
        [self setTitle:@""
              forState:UIControlStateNormal];
    }
}

-(void)cleanUp
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
