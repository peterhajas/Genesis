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

#import "GNTabArrowGlyphView.h"
#import "GNTextInputAccessoryView.h"
#import "GNTextInputAccessoryViewButton.h"

@implementation GNTabArrowGlyphView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self setBackgroundColor:[UIColor clearColor]];
        [[self layer] setRasterizationScale:[[UIScreen mainScreen] scale]];
        [self setUserInteractionEnabled:NO];
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
    // Draw our tab glyph!
    
    // ->|
    
    /*
     The tab glyph has three main components:
     
     1 - The horizontal line leading to the left
     2 - The vertical line on the right
     3 - The two diagonal lines, the arrow part, pointing at 2
     */
    
    // The color we'll use
    CGColorRef glyphColor = [[UIColor blackColor] CGColor];
    
    // The thickness of our lines
    CGFloat lineThickness = 2.0;
    
    // Draw the horizontal line
    
    CGContextRef context = UIGraphicsGetCurrentContext();
        
    CGPoint horizontalLineStart = CGPointMake(kGNTextInputAccessoryViewButtonMargin * 4,
                                              kGNTextInputAccessoryViewHeight/2);
    CGPoint horizontalLineEnd = CGPointMake(kGNTextInputAccessoryViewButtonWidth - 7 * kGNTextInputAccessoryViewButtonMargin,
                                            horizontalLineStart.y);
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, glyphColor);
    CGContextSetLineWidth(context, lineThickness);
    CGContextMoveToPoint(context, horizontalLineStart.x, horizontalLineStart.y);
    CGContextAddLineToPoint(context, horizontalLineEnd.x, horizontalLineEnd.y);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    // Draw the vertical line
    
    CGPoint verticalLineStart = CGPointMake(horizontalLineEnd.x + 3 * kGNTextInputAccessoryViewButtonMargin,
                                            [self frame].size.height - kGNTextInputAccessoryViewButtonMargin * 3);
    
    CGPoint verticalLineEnd = CGPointMake(verticalLineStart.x,
                                          kGNTextInputAccessoryViewButtonMargin * 3);
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, glyphColor);
    CGContextSetLineWidth(context, lineThickness);
    CGContextMoveToPoint(context, verticalLineStart.x, verticalLineStart.y);
    CGContextAddLineToPoint(context, verticalLineEnd.x, verticalLineEnd.y);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    // Draw the upper-left to lower-right portion of the diagonal
    
    CGPoint upperLeftLineStart = CGPointMake(verticalLineStart.x - kGNTextInputAccessoryViewButtonMargin * 6,
                                             horizontalLineStart.y - kGNTextInputAccessoryViewButtonMargin * 2);
    CGPoint upperLeftLineEnd = CGPointMake(verticalLineStart.x - kGNTextInputAccessoryViewButtonMargin * 2,
                                           kGNTextInputAccessoryViewHeight/2);
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, glyphColor);
    CGContextSetLineWidth(context, lineThickness);
    CGContextMoveToPoint(context, upperLeftLineStart.x, upperLeftLineStart.y);
    CGContextAddLineToPoint(context, upperLeftLineEnd.x, upperLeftLineEnd.y);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    // Draw the lower-left to upper-right portion of the diagonal
    
    CGPoint lowerLeftStart = CGPointMake(upperLeftLineStart.x,
                                         horizontalLineStart.y + (horizontalLineStart.y - upperLeftLineStart.y));
    CGPoint lowerLeftEnd = CGPointMake(upperLeftLineEnd.x,
                                       upperLeftLineEnd.y);
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, glyphColor);
    CGContextSetLineWidth(context, lineThickness);
    CGContextMoveToPoint(context, lowerLeftStart.x, lowerLeftStart.y);
    CGContextAddLineToPoint(context, lowerLeftEnd.x, lowerLeftEnd.y);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

-(BOOL)canBecomeFirstResponder
{
    return NO;
}

@end
