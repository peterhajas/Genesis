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

#import "GNTextOverlayView.h"

@implementation GNTextOverlayView

-(id)init
{
    self = [super initWithFrame:CGRectMake(0,
                                           0,
                                           0,
                                           0)];
    
    contentOffset = CGPointMake(0, 0);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(horizontalOffsetChanged:)
                                                 name:GNHorizontalOffsetChangedNotification
                                               object:nil];
    
    return self;
}

-(void)setFrame:(CGRect)frame
{
    nonOffsetFrame = frame;
    [self recalculateFrame];
}

-(void)horizontalOffsetChanged:(NSNotification*)notification
{
    CGFloat newHorizontalOffset = [[notification object] floatValue];
    [self setHorizontalOffset:newHorizontalOffset];
}

-(CGFloat)horizontalOffset
{
    return contentOffset.x;
}

-(void)setHorizontalOffset:(CGFloat)horizontalOffset
{
    contentOffset = CGPointMake(horizontalOffset,
                                contentOffset.y);
    [self recalculateFrame];
}

-(CGFloat)verticalOffset
{
    return contentOffset.y;
}

-(void)setVerticalOffset:(CGFloat)verticalOffset
{
    contentOffset = CGPointMake(contentOffset.x,
                                verticalOffset);
    [self recalculateFrame];
}

-(void)recalculateFrame
{
    CGRect frame = nonOffsetFrame;
    CGRect newFrame = CGRectMake(frame.origin.x - contentOffset.x,
                                 frame.origin.y - contentOffset.y,
                                 frame.size.width,
                                 frame.size.height);
    [super setFrame:newFrame];
}

#pragma mark Lifecycle cleanup methods

-(void)cleanUp
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
