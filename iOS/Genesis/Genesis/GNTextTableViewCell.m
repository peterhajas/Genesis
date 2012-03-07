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

#import "GNTextTableViewCell.h"

#define DEFAULT_FONT_FAMILY @"Courier"
#define DEFAULT_SIZE 16

static CTFontRef defaultFont = nil;

@implementation GNTextTableViewCell

-(id)initWIthLine:(NSString*)line
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kGNTextTableViewCellReuseIdentifier];
    if(self)
    {
        representedLine = line;
        
        // Attributed string with representedLine's text
        attributedLine = [[NSAttributedString alloc] initWithString:representedLine];
        
        syntaxHighlighter = [[GNSyntaxHighlighter alloc] initWithDelegate:self];
        [self addSubview:syntaxHighlighter];
                
        // Create the default font (later should be done in preferences)
        defaultFont = CTFontCreateWithName((CFStringRef)DEFAULT_FONT_FAMILY,
                                           DEFAULT_SIZE,
                                           NULL);
    }
    
    return self;
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    staleContext = UIGraphicsGetCurrentContext();
    
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)attributedLine;
    CTLineRef line = CTLineCreateWithAttributedString(attributedString);
    
    CGContextSetTextPosition(staleContext, 5.0, 5.0);
    CTLineDraw(line, staleContext);
}

#pragma mark GNSyntaxHighlighterDelegate methods

-(void)didHighlightText:(NSAttributedString *)highlightedText
{
    attributedLine = highlightedText;
    [self setNeedsDisplay];
}

@end
