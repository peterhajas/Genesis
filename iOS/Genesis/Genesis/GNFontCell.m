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

#import "GNFontCell.h"
#define kGNTextLabelOffset 10.0

@implementation GNFontCell

-(id)initWithFontWithName:(NSString*)name size:(CGFloat)size
{
    self = [super initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:GNFontCellReuseIdentifier];
    if(self)
    {
        NSString* text = [NSString stringWithFormat:@"%@ %.1f",name,size];
        label = [[GNAttributedTextLabel alloc] initWithText:text
                                                       font:[UIFont fontWithName:name
                                                                            size:size]];
        [label setFrame:CGRectMake(kGNTextLabelOffset,
                                   0.0,
                                   [label frame].size.width + kGNTextLabelOffset,
                                   [label frame].size.height)];
        [self addSubview:label];
    }
    
    return self;
}

@end
