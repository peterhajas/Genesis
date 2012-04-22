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

#import "GNAttributedTextLabel.h"

@implementation GNAttributedTextLabel

-(id)initWithText:(NSString*)text font:(UIFont*)font
{
    CGSize sizeRequired = [text sizeWithFont:font];
    self = [super initWithFrame:CGRectMake(0,
                                           0,
                                           sizeRequired.width,
                                           sizeRequired.height)];
    if(self)
    {
        attributedString = [[NSMutableAttributedString alloc] initWithString:text];
        
        CTFontRef ctfont = CTFontCreateWithName((__bridge CFStringRef)[font fontName],
                                                [font pointSize],
                                                NULL);
        
        [attributedString setAttributes:[NSDictionary dictionaryWithObject:(__bridge id)(ctfont)
                                                                    forKey:(NSString*)kCTFontAttributeName]
                                  range:NSMakeRange(0, [text length])];
        
        
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
    NSLog(@"text: %@", attributedString);
    CGContextRef context = UIGraphicsGetCurrentContext();
        
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    
    // Account for Cocoa coordinate system
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -[self frame].size.height);
    
    CGContextSetTextPosition(context,
                             [self frame].origin.x,
                             [self frame].origin.y);

    CTLineDraw(line, context);
    
    if(context)
    {
        CTLineDraw(line, context);
    }
}

@end
