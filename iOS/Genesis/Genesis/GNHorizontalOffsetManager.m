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

#import "GNHorizontalOffsetManager.h"

@implementation GNHorizontalOffsetManager

@synthesize delegate;

-(id)init
{
    self = [super init];
    if(self)
    {
        horizontalOffsets = [[NSMutableArray alloc] init];
    }
    return self;
}

-(CGFloat)horizontalOffsetForLineAtIndex:(NSUInteger)index
{
    if(index < [horizontalOffsets count])
    {
        return [[horizontalOffsets objectAtIndex:index] floatValue];
    }
    return 0.0;
}

-(void)setHorizontalOffset:(CGFloat)scrollOffset forLineAtIndex:(NSUInteger)index
{
    NSNumber* newHorizontalOffset = [NSNumber numberWithFloat:scrollOffset];
    [horizontalOffsets replaceObjectAtIndex:index withObject:newHorizontalOffset];
}

-(void)insertLineWithEmptyHorizontalOffsetAtIndex:(NSUInteger)index
{
    [horizontalOffsets insertObject:[NSNumber numberWithFloat:0.0]
                            atIndex:index];
}

-(void)removeLineWithEmptyHorizontalOffsetAtIndex:(NSUInteger)index
{
    [horizontalOffsets removeObjectAtIndex:index];
}

-(void)clearHorizontalOffsets
{
    for(NSUInteger i = 0; i < [delegate lineCount]; i++)
    {
        [horizontalOffsets addObject:[NSNumber numberWithFloat:0.0]];
    }
}

@end
