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

#import "GNTextLineView.h"

@implementation GNTextLineView

#define DEFAULT_FONT_FAMILY @"Courier"

static CTFontRef defaultFont = nil;

-(id)initWithLine:(NSString*)lineText frame:(CGRect)frame andSizingDelegate:(NSObject<GNTextLineViewSizingDelegate>*)sizingDelegate
{
    self = [super initWithFrame:frame];
    if(self)
    {
        representedLineText = lineText;
        
        // Set our line ivar to nil
        line = nil;
        
        // Attributed string with representedLine's text
        attributedLine = [[NSAttributedString alloc] initWithString:representedLineText];
        
        syntaxHighlighter = [[GNSyntaxHighlighter alloc] initWithDelegate:self];
        [self addSubview:syntaxHighlighter];
        
        [syntaxHighlighter highlightText:representedLineText];
        
        // Create the default font (later should be done in preferences)
        defaultFont = CTFontCreateWithName((CFStringRef)DEFAULT_FONT_FAMILY,
                                           DEFAULT_SIZE,
                                           NULL);
        
        delegate = sizingDelegate;
        
        // Re-evaluate our size, in case we need to be larger
        UIFont* defaultUIFont = [UIFont fontWithName:DEFAULT_FONT_FAMILY
                                                size:DEFAULT_SIZE];
        
        CGSize sizeRequiredForText = [representedLineText sizeWithFont:defaultUIFont];
        
        if(sizeRequiredForText.width > [self frame].size.width)
        {
            [self setFrame:CGRectMake([self frame].origin.x,
                                      [self frame].origin.y,
                                      sizeRequiredForText.width,
                                      [self frame].size.height)];
        }
        
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    
    return self;
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    staleContext = UIGraphicsGetCurrentContext();
    
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)attributedLine;
    if(line != nil)
    {
        CFRelease(line);
    }
    line = CTLineCreateWithAttributedString(attributedString);
    
    // Account for Cocoa coordinate system
    CGContextScaleCTM(staleContext, 1, -1);
    CGContextTranslateCTM(staleContext, 0, -[self frame].size.height);
    
    CGContextSetTextPosition(staleContext, 5.0, 5.0);
    CTLineDraw(line, staleContext);
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [delegate requiresWidth:frame.size.width];
}

#pragma mark Hit-testing
-(CFIndex)indexForTappedPoint:(CGPoint)point
{
    CFIndex indexIntoString = CTLineGetStringIndexForPosition(line, point);
    
    if(indexIntoString == kCFNotFound)
    {
        indexIntoString = 0;
    }
    
    return indexIntoString;
}


#pragma mark GNSyntaxHighlighterDelegate methods

-(void)didHighlightText:(NSAttributedString *)highlightedText
{
    attributedLine = highlightedText;
    [self setNeedsDisplay];
}


@end
