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

#import "GNTextView.h"

@implementation GNTextView

-(void)awakeFromNib
{
    innerView = [[GNTextInnerView alloc] initWithFrame:[self frame]];
    [innerView setContainerDelegate:self];
    
    [self addSubview:innerView];
    
    [innerView fitFrameToText];
    CGSize sizeForTextview = [innerView frame].size;
    
    [self setContentSize:sizeForTextview];
}

-(void)requiresSize:(CGSize)size
{
    [self setContentSize:size];
}

-(BOOL)resignFirstResponder
{
    [innerView resignFirstResponder];
    return [super resignFirstResponder];
}

-(void)requireSize:(CGSize)size
{
    [self setContentSize:size];
    NSLog(@"scrollview content height: %f", size.height);
}

#pragma mark Text Handling

-(void)setText:(NSString*)text
{
    [innerView setShownText:text];
}

-(NSString*)text
{
    return [innerView shownText];
}

@end
