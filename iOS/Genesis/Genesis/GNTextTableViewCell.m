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

@implementation GNTextTableViewCell

@synthesize fileRepresentation;

-(id)initWithLine:(NSString*)lineText atIndex:(NSUInteger)index
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kGNTextTableViewCellReuseIdentifier];
    if(self)
    {
        textLineView = [[GNTextLineView alloc] initWithLine:lineText
                                                   andFrame:[self frame]];
        [self addSubview:textLineView];
        
        lineNumber = index;
        
        // Create our tap gesture recognizer
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(handleTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];
    }
    
    return self;
}

-(void)handleTap:(UITapGestureRecognizer*)sender
{
    if([sender state] == UIGestureRecognizerStateEnded)
    {
        CGPoint touchLocation = [sender locationInView:self];
        CFIndex indexIntoString = [textLineView indexForTappedPoint:touchLocation];
                
        [fileRepresentation setInsertionToLineAtIndex:lineNumber
                                 characterIndexInLine:indexIntoString];
        
        [self resignFirstResponder];
    }
}

@end
