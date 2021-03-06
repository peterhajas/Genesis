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
#import "GNLineNumberTableView.h"
#import "GNTextGeometry.h"

@implementation GNTextLineView

@synthesize line,staleContext;

-(id)initWithFileRepresentation:(GNFileRepresentation*)representation lineNumber:(NSUInteger)number frame:(CGRect)frame andSizingDelegate:(NSObject<GNTextLineViewSizingDelegate>*)sizingDelegate
{
    self = [super initWithFrame:frame];
    if(self)
    {
        fileRepresentation = representation;
        lineNumber = number;
        
        // Set our line ivar to nil
        line = nil;
        
        // Attributed string with representedLine's text
        NSAttributedString* attributedLine = [[representation attributedFileText] attributedLineAtIndex:lineNumber];
        
        // Highlight attributedLine
        highlightedLine = [GNSyntaxHighlighter highlightedSyntaxForAttributedText:attributedLine];
        
        delegate = sizingDelegate;
        
        // Re-evaluate our size, in case we need to be larger
        [self setFrame:frame];
                
        [self setBackgroundColor:[UIColor clearColor]];
        
        // Set our autoresizing mask
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        // Subscribe to text notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textChanged)
                                                     name:GNTextChangedNotification
                                                   object:nil];
    }
    
    return self;
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    staleContext = UIGraphicsGetCurrentContext();
    
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)highlightedLine;
    if(line != nil)
    {
        CFRelease(line);
    }
    
    line = CTLineCreateWithAttributedString(attributedString);
    
    // Account for Cocoa coordinate system
    CGContextScaleCTM(staleContext, 1, -1);
    CGContextTranslateCTM(staleContext, 0, -[self frame].size.height);
    
    CGContextSetTextPosition(staleContext, 0.0, [GNTextGeometry fontSize] * 0.25);
    CTLineDraw(line, staleContext);
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self fitSizeToText];
}

-(void)fitSizeToText
{
    UIFont* defaultUIFont = [GNTextGeometry font];
    
    CGFloat widthRequiredForText = [[highlightedLine string] sizeWithFont:defaultUIFont].width;
    
    if(widthRequiredForText > [[self superview] frame].size.width)
    {
        widthRequiredForText += kGNLineNumberTableViewWidth;
    }
    
    CGRect oldFrame = [self frame];
    CGRect newFrame = CGRectMake(oldFrame.origin.x,
                                 oldFrame.origin.y,
                                 widthRequiredForText,
                                 oldFrame.size.height);
    [super setFrame:newFrame];
    
    [delegate requiresWidth:widthRequiredForText];
}

-(void)setLineNumber:(NSUInteger)lineIndex
{
    // Our line number has changed.
    lineNumber = lineIndex;
    [self textChanged];
}

-(void)textChanged
{
    // Grab our new attributedLine
    if(lineNumber < [[fileRepresentation fileText] lineCount])
    {
        NSAttributedString* attributedLine = [[fileRepresentation attributedFileText] attributedLineAtIndex:lineNumber];
        // Highlight attributedLine
        highlightedLine = [GNSyntaxHighlighter highlightedSyntaxForAttributedText:attributedLine];
    }
    else
    {
        // If they're asking for a line that doesn't exist, make it a blank string
        highlightedLine = [[NSAttributedString alloc] initWithString:@""];
    }
        
    // Re-evaluate our size
    [self setFrame:[self frame]];
    [self setNeedsDisplay];
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

@end
