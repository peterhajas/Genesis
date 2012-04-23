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

#import "GNSelectionPointManager.h"

@implementation GNSelectionPointManager

@synthesize stringLength;
@synthesize selectionRange;

-(id)init
{
    self = [super init];
    if(self)
    {
        selectionRange = NSMakeRange(0, 0);
        stringLength = 0;
    }
    return self;
}

-(NSUInteger)leftSelectionIndex
{
    return selectionRange.location;
}

-(void)setLeftSelectionIndex:(NSUInteger)leftSelectionIndex
{
    NSUInteger rightSelectionIndex = [self rightSelectionIndex];
    
    selectionRange = NSMakeRange(leftSelectionIndex,
                                 rightSelectionIndex - leftSelectionIndex);
    [self selectionDidChange];
}

-(NSUInteger)rightSelectionIndex
{
    return selectionRange.location + selectionRange.length;
}

-(void)setRightSelectionIndex:(NSUInteger)rightSelectionIndex
{
    NSInteger lengthDifference = rightSelectionIndex - [self rightSelectionIndex];
    selectionRange = NSMakeRange(selectionRange.location,
                                 selectionRange.length + lengthDifference);
    [self selectionDidChange];
}

-(void)selectionDidChange
{
    [[NSNotificationCenter defaultCenter] postNotificationName:GNSelectionPointsChangedNotification object:self];
}

@end
