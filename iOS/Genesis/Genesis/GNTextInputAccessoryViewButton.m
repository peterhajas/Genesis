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

#import "GNTextInputAccessoryViewButton.h"
#import "GNTextInputAccessoryView.h"

@implementation GNTextInputAccessoryViewButton

-(id)init
{
    self = [GNTextInputAccessoryViewButton buttonWithType:UIButtonTypeCustom];
    if(self)
    {
        [self setFrame:CGRectMake(0,
                                  kGNTextInputAccessoryViewButtonMargin,
                                  kGNTextInputAccessoryViewButtonWidth,
                                  [GNTextInputAccessoryView appropriateHeight] - (kGNTextInputAccessoryViewButtonMargin * 2))];
        
        // Create our gradient layer
        CAGradientLayer* gradientLayer = [CAGradientLayer layer];
        [gradientLayer setColors:kGNTextInputAccessoryGradientColors];
        [gradientLayer setFrame:[self frame]];
        [[self layer] addSublayer:gradientLayer];
    }
    
    return self;
}

-(void)setHorizontalPosition:(CGFloat)horizontalPosition
{
    CGRect currentFrame = [self frame];
    [self setFrame:CGRectMake(horizontalPosition,
                              currentFrame.origin.y,
                              currentFrame.size.width,
                              currentFrame.size.height)];
}

@end
