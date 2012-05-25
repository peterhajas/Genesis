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

#import "GNInsertionPointManager.h"

@implementation GNInsertionPointManager

@synthesize stringLength;
@synthesize announcerDelegate;
@synthesize delegate;

-(id)init
{
    self = [super init];
    if(self)
    {
        insertionIndex = 0;
        insertionIndexInLine = 0;
        insertionLine = 0;
        stringLength = 0;
    }
    return self;
}

-(void)incrementInsertionByLength:(NSUInteger)length isNewLine:(BOOL)isNewLine
{
    [self insertionPointWillChange];
    insertionIndex+=length;
    insertionIndexInLine+=length;
    if(isNewLine)
    {
        insertionIndexInLine = length - 1;
        insertionLine++;
    }
    [self insertionPointChanged];
}

-(void)decrement
{
    [self insertionPointWillChange];
    if(insertionIndexInLine >= 1)
    {
        insertionIndex--;
        insertionIndexInLine--;
    }
    
    [self insertionPointChanged];
}

-(void)decrementByCount:(NSUInteger)count
{
    [self insertionPointWillChange];
    if(insertionIndexInLine >= count)
    {
        insertionIndex-=count;
        insertionIndexInLine-=count;
    }
    
    [self insertionPointChanged];
}

-(void)decrementToPreviousLineWithOldLineLength:(NSUInteger)oldLineLength newLineLength:(NSUInteger)newLineLength
{
    [self insertionPointWillChange];
    insertionLine--;
    insertionIndexInLine = newLineLength;
    
    [self insertionPointChanged];
}

-(BOOL)insertionIsAtStartOfFile
{
    return insertionIndex == 0;
}

-(void)setInsertionToLineAtIndex:(NSUInteger)lineIndex characterIndexInLine:(NSUInteger)characterIndex
{
    [self insertionPointWillChange];
    insertionIndex = [delegate characterCountToLineAtIndex:lineIndex];
    
    insertionLine = lineIndex;
    
    insertionIndex+=characterIndex;
    
    insertionIndexInLine = characterIndex;
    
    if(insertionIndex > stringLength)
    {
        insertionIndex--;
        insertionIndexInLine--;
    }
    
    [self insertionPointChanged];
}

-(NSUInteger)insertionIndex
{
    return insertionIndex;
}

-(void)setInsertionIndex:(NSUInteger)index
{
    [self insertionPointWillChange];
    insertionIndex = index;
    [self insertionPointChanged];
}

-(NSUInteger)insertionIndexInLine
{
    return insertionIndexInLine;
}

-(void)setInsertionIndexInLine:(NSUInteger)index
{
    [self insertionPointWillChange];
    insertionIndexInLine = index;
    [self insertionPointChanged];
}

-(NSUInteger)insertionLine
{
    return insertionLine;
}

-(void)setInsertionLine:(NSUInteger)index
{
    [self insertionPointWillChange];
    insertionLine = index;
    [self insertionPointChanged];
}

-(NSUInteger)absoluteInsertionIndex
{
    return insertionIndex + insertionLine;
}

-(void)insertionPointWillChange
{
    [announcerDelegate insertionPointWillChange];
}

-(void)insertionPointChanged
{
    [announcerDelegate insertionPointDidChange];
}

@end
