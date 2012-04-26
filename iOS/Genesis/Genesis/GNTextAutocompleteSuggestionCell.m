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

#import "GNTextAutocompleteSuggestionCell.h"
#import "GNTextGeometry.h"

@implementation GNTextAutocompleteSuggestionCell

-(id)initWithText:(NSString*)text
{
    self = [super initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:@"kGNAutoCompleteCell"];
    if(self)
    {
        // Create a UIView for our content
        UIView* content = [[UIView alloc] initWithFrame:[self frame]];
        [content setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
        
        // Set background gradient
        gradient = [CAGradientLayer layer];
        [gradient setFrame:[self bounds]];
        [gradient setColors:kGNTextAutocompleteCellDefaultGradientColors];
        
        [[content layer] addSublayer:gradient];
        
        // Create a UILabel for the text
        UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectMake(kGNTextAutocompleteCellLabelMargin,
                                                                       kGNTextAutocompleteCellLabelMargin,
                                                                       [self frame].size.width - 2 * kGNTextAutocompleteCellLabelMargin,
                                                                       [self frame].size.height - 2 * kGNTextAutocompleteCellLabelMargin)];
        [textLabel setText:text];
        [textLabel setFont:[UIFont fontWithName:[[GNSharedSettings sharedSettings] valueForKey:GNSettingsFontFaceKey]
                                           size:20]];
        [textLabel setBackgroundColor:[UIColor clearColor]];
        [textLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin)];
        
        [content addSubview:textLabel];
        
        [self addSubview:content];
    }
    return self;
}

-(void)layoutSubviews
{
    [gradient setFrame:[self bounds]];
    [super layoutSubviews];
}

-(void)gradientUpsideDown
{
    [gradient setColors:kGNTextAutocompleteCellInvertedGradientColors];
}

-(void)gradientRightSideUp
{
    [gradient setColors:kGNTextAutocompleteCellDefaultGradientColors];
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self gradientUpsideDown];
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self gradientRightSideUp];
    [super touchesEnded:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self gradientRightSideUp];
    [super touchesCancelled:touches withEvent:event];
}

@end
