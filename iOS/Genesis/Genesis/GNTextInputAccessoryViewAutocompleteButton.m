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
#import "GNTextGeometry.h"

@implementation GNTextInputAccessoryViewAutocompleteButton
@synthesize topAutocompleteSuggestion;

-(id)init
{
    self = [super init];
    if(self)
    {
        [self setFrame:CGRectMake([self frame].origin.x,
                                  [self frame].origin.y,
                                  2 * kGNTextInputAccessoryViewButtonWidth,
                                  [self frame].size.height)];
        [button setFrame:[self frame]];
                
        topAutocompleteSuggestion = @"";
        
        isShowingAlternateView = NO;
        multipleSuggestions = NO;
        
        // Create the top suggestion label
        topAutocompleteSuggestionLabel = [[UILabel alloc] initWithFrame:CGRectMake([self frame].origin.x + kGNTextInputAccessoryViewButtonMargin,
                                                                                   [self frame].origin.y,
                                                                                   [self frame].size.width - (0.5 * kGNTextInputAccessoryViewButtonWidth) - kGNTextInputAccessoryViewButtonMargin,
                                                                                   [self frame].size.height)];
        [topAutocompleteSuggestionLabel setBackgroundColor:[UIColor clearColor]];
        [topAutocompleteSuggestionLabel setFont:[GNTextGeometry font]];
        [topAutocompleteSuggestionLabel setTextAlignment:UITextAlignmentLeft];
        [topAutocompleteSuggestionLabel setTextColor:[UIColor blackColor]];
        [topAutocompleteSuggestionLabel setText:@""];
        [self insertSubview:topAutocompleteSuggestionLabel belowSubview:button];
        
        // Create the "number of suggestions" view
        numberOfSuggestions = [[UIView alloc] initWithFrame:CGRectMake([self frame].origin.x + 0.75 * kGNTextInputAccessoryViewButtonWidth,
                                                                       [self frame].origin.y,
                                                                       0.5 * kGNTextInputAccessoryViewButtonWidth,
                                                                       [self frame].size.height)];
        
        CAGradientLayer* numberOfSuggestionsGradient = [CAGradientLayer layer];
        [numberOfSuggestionsGradient setFrame:[numberOfSuggestions frame]];
        [numberOfSuggestionsGradient setColors:[NSArray arrayWithObjects:(id)[[UIColor darkGrayColor] CGColor],
                                                                         (id)[[UIColor blackColor] CGColor],
                                                                         nil]];
        
        [[numberOfSuggestions layer] addSublayer:numberOfSuggestionsGradient];
        numberOfSuggestionsLabel = [[UILabel alloc] initWithFrame:[numberOfSuggestions frame]];
        [numberOfSuggestionsLabel setBackgroundColor:[UIColor clearColor]];
        [numberOfSuggestionsLabel setFont:[UIFont systemFontOfSize:20.0]];
        [numberOfSuggestionsLabel setTextAlignment:UITextAlignmentCenter];
        [numberOfSuggestionsLabel setTextColor:[UIColor whiteColor]];
        [numberOfSuggestionsLabel setText:@"1"];
        [numberOfSuggestions addSubview:numberOfSuggestionsLabel];
        
        // Configure our button to point to us
        [button addTarget:self
                   action:@selector(buttonPushed)
         forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    [gradientLayer setFrame:[self frame]];
}

-(void)setHorizontalPosition:(CGFloat)horizontalPosition
{
    [super setHorizontalPosition:horizontalPosition];
    [topAutocompleteSuggestionLabel setFrame:CGRectMake([self frame].origin.x + kGNTextInputAccessoryViewButtonMargin,
                                                        [self frame].origin.y,
                                                        [self frame].size.width - (0.5 * kGNTextInputAccessoryViewButtonWidth) - kGNTextInputAccessoryViewButtonMargin,
                                                        [self frame].size.height)];
    [numberOfSuggestions setFrame:CGRectMake([self frame].origin.x + 0.75 * kGNTextInputAccessoryViewButtonWidth,
                                             [self frame].origin.y,
                                             0.5 * kGNTextInputAccessoryViewButtonWidth,
                                             [self frame].size.height)];
}

-(void)buttonPushed
{
    if(isShowingAlternateView)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:GNSwitchToSystemKeyboardNotification object:nil];
        [gradientLayer setColors:kGNTextInputAccessoryViewButtonDefaultColors];
        if(multipleSuggestions)
        {
            [self showNumberOfSuggestions];
        }
        isShowingAlternateView = NO;
        [topAutocompleteSuggestionLabel setText:topAutocompleteSuggestion];
    }
    else
    {
        if(multipleSuggestions)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:GNSwitchToAutoCompleteKeyboardNotification object:nil];
            [gradientLayer setColors:kGNTextInputAccessoryViewAutocompleteButtonCancelColors];
            [self hideNumberOfSuggestions];
            isShowingAlternateView = YES;
            [topAutocompleteSuggestionLabel setText:kGNTextInputAccessoryViewAutocompleteButtonCancelText];

        }
        else
        {
            // Right now, be hacky, and announce this over a notification
            // TODO: wrap this in something more sane
            [[NSNotificationCenter defaultCenter] postNotificationName:GNReplaceCurrentWordNotification object:topAutocompleteSuggestion];
            [gradientLayer setColors:kGNTextInputAccessoryViewButtonDefaultColors];
        }
    }
}

-(void)setNumberOfSuggestions:(NSUInteger)suggestions
{
    NSString* numberOfSuggestionsString;
    if(suggestions < 10)
    {
        numberOfSuggestionsString = [[NSNumber numberWithInt:suggestions] stringValue];
    }
    else
    {
        numberOfSuggestionsString = @"9+";
    }
    [numberOfSuggestionsLabel setText:numberOfSuggestionsString];
}

-(void)showNumberOfSuggestions
{
    if(![numberOfSuggestions superview])
    {
        [self insertSubview:numberOfSuggestions belowSubview:topAutocompleteSuggestionLabel];
    }
}

-(void)hideNumberOfSuggestions
{
    if([numberOfSuggestions superview])
    {
        [numberOfSuggestions removeFromSuperview];
    }
}

-(void)insertionPointChanged:(id)object
{
    GNFileRepresentation* fileRepresentation = [object object];
    
    NSString* currentWord = [[fileRepresentation fileText] currentWord];
    
    NSArray* autocorrectionSuggestions = [[fileRepresentation autoCompleteDictionary] orderedMatchesForText:currentWord];
    
    [self setNumberOfSuggestions:[autocorrectionSuggestions count]];
    
    // Set our title to the top autocorrection match
    if([autocorrectionSuggestions count] > 0)
    {
        NSString* firstMatch = [autocorrectionSuggestions objectAtIndex:0];
        
        topAutocompleteSuggestion = firstMatch;
        if([autocorrectionSuggestions count] > 1)
        {   
            [self showNumberOfSuggestions];
            multipleSuggestions = YES;
        }
        else
        {
            [self hideNumberOfSuggestions];
            multipleSuggestions = NO;
        }
    }
    else
    {
        topAutocompleteSuggestion = @"";
        [self hideNumberOfSuggestions];
    }
    
    [topAutocompleteSuggestionLabel setText:topAutocompleteSuggestion];
}

-(void)registerForNotifications
{
    // Subscribe to the text changed notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(insertionPointChanged:)
                                                 name:GNInsertionPointChangedNotification
                                               object:nil];
}

-(void)cleanUp
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
