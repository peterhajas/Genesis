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

#import "GNFileText.h"
#import "GNTextGeometry.h"

@implementation GNFileText

@synthesize fileText;
@synthesize fileLines;

@synthesize insertionPointManager;
@synthesize horizontalOffsetManager;

@synthesize fileTextDelegate;

-(id)initWithData:(NSData*)contents
{
    self = [super init];
    if(self)
    {
        fileText = [[NSString alloc] initWithData:contents
                                         encoding:NSUTF8StringEncoding];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(insertTabAtInsertionPoint)
                                                     name:GNInsertTabAtInsertionPointNotification
                                                   object:nil];
        
        [self textChanged];
    }
    return self;
}



-(BOOL)hasText
{
    return [fileText length] > 0;
}

-(void)insertText:(NSString*)text
{    
    if(![text isEqualToString:@"\n"])
    {
        if([fileText isEqualToString:@""])
        {
            fileText = [fileText stringByAppendingString:text];
        }
        else
        {
            // Grab the text before and after the insertion point
            NSString* beforeInsertion = [fileText substringToIndex:[insertionPointManager absoluteInsertionIndex]];
            NSString* afterInsertion = [fileText substringFromIndex:[insertionPointManager absoluteInsertionIndex]];
            
            // Concatenate beforeInsertion + text + afterInsertion
            fileText = [beforeInsertion stringByAppendingString:text];
            fileText = [fileText stringByAppendingString:afterInsertion];
        }
        
        [self textChanged];
        
        // Increment the insertion index by the length of text
        [insertionPointManager incrementInsertionByLength:[text length] isNewLine:NO];
    }
    else
    {
        [self insertNewline];
    }
}

-(void)insertText:(NSString *)text indexDelta:(NSInteger)delta
{
    [self insertText:text];
    [insertionPointManager incrementInsertionByLength:delta isNewLine:NO];
}

-(void)replaceTextInRange:(NSRange)range withText:(NSString*)text
{
    // Compute how far we'll have to move our insertion index
    NSInteger delta = [text length] - range.length;
    
    fileText = [fileText stringByReplacingCharactersInRange:range withString:text];
    [self textChanged];
    [insertionPointManager incrementInsertionByLength:delta isNewLine:NO];
}

-(void)deleteBackwards
{
    if([insertionPointManager insertionIsAtStartOfFile])
    {
        // Don't do anything. We can't move back.
        return;
    }
    
    // Grab the text before the insertion point minus 1 and the text after insertion
    NSString* beforeInsertion = [fileText substringToIndex:[insertionPointManager absoluteInsertionIndex] - 1];
    NSString* afterInsertion = [fileText substringFromIndex:[insertionPointManager absoluteInsertionIndex]];
    
    // Set the new file contents
    fileText = [beforeInsertion stringByAppendingString:afterInsertion];
    
    if([insertionPointManager insertionIndexInLine] >= 1)
    {
        [self textChanged];
        [insertionPointManager decrement];
    }
    
    /*
     If insertionIndexInLine is 0, then we compute the new insertion indices
     manually. insertionLine will be the previous line. insertionIndexInLine
     will be the length of the line we're moving to minus the length of the
     line that is being concatenated with it (previousCurrentLineLength).
     */
    
    else
    {
        NSUInteger previousCurrentLineLength = [[self currentLine] length];
        NSString* newLine = [fileLines objectAtIndex:[insertionPointManager insertionLine]-1];
        NSUInteger newLineLength = [newLine length];
        
        [self textChanged];
        
        [horizontalOffsetManager removeLineWithEmptyHorizontalOffsetAtIndex:[insertionPointManager insertionLine]];
        
        [insertionPointManager decrementToPreviousLineWithOldLineLength:previousCurrentLineLength newLineLength:newLineLength];
    }
}

-(void)insertNewline
{
    NSUInteger start, end;
    NSString* lineSubstring;
    NSString* leadingSpaces;
    NSRange leadingSpacesRange;
    
    [fileText getLineStart:&start 
                           end:&end
                   contentsEnd:NULL
                      forRange:NSMakeRange([insertionPointManager insertionIndex],
                                           [fileText length] - [insertionPointManager insertionIndex])];
    
    NSRegularExpression* leadingSpacesRegex = [NSRegularExpression regularExpressionWithPattern:@"^([[:blank:]]*)" 
                                                                                        options:NSRegularExpressionCaseInsensitive
                                                                                          error:nil];
    
    lineSubstring = [self currentLine];
    
    NSString* textToInsert = @"";
    
    if([lineSubstring length] > 0)
    {
        
        NSTextCheckingResult* textCheckingResult = [leadingSpacesRegex firstMatchInString:lineSubstring 
                                                                                  options:NSMatchingAnchored 
                                                                                    range:[lineSubstring
                                                                                           rangeOfString:lineSubstring]];
        
        leadingSpacesRange = [textCheckingResult range];
        
        if(leadingSpacesRange.location != NSNotFound)
        {
            leadingSpaces = [lineSubstring substringWithRange:leadingSpacesRange];
        }
        else
        {
            leadingSpaces = @"";
        }
        
        textToInsert = [@"\n" stringByAppendingString:leadingSpaces];
        
    }
    else
    {
        textToInsert = @"\n";
    }
    
    // Grab the text before and after the insertion point
    NSString* beforeInsertion = [fileText substringToIndex:[insertionPointManager absoluteInsertionIndex]];
    NSString* afterInsertion = [fileText substringFromIndex:[insertionPointManager absoluteInsertionIndex]];
    
    // Concatenate beforeInsertion + textToInsert + afterInsertion
    fileText = [beforeInsertion stringByAppendingString:textToInsert];
    fileText = [fileText stringByAppendingString:afterInsertion];
    
    [self textChanged];
    
    [insertionPointManager incrementInsertionByLength:[textToInsert length] isNewLine:YES];
    [fileTextDelegate horizontalOffsetManagerShouldInsertLineAtIndex:[insertionPointManager insertionLine]];
}

-(void)textChanged
{
    [self refreshFileLines];
    [fileTextDelegate textDidChange];
}

-(NSString*)currentLine
{
    return [fileLines objectAtIndex:[insertionPointManager insertionLine]];
}

-(NSUInteger)lineCount
{
    return [fileLines count];
}

-(NSString*)lineAtIndex:(NSUInteger)index
{
    return [fileLines objectAtIndex:index];
}


-(NSString*)lineToInsertionPoint
{
    if([[self currentLine] isEqualToString:@""])
    {
        return @"";
    }
    return [[self currentLine] substringToIndex:[insertionPointManager insertionIndexInLine]];
}

-(NSRange)rangeOfLineAtIndex:(NSUInteger)index
{
    NSUInteger location = 0;
    // For location, count up the length of all lines up until the line at index
    for(NSUInteger i = 0; i < index; i++)
    {
        location += [[fileLines objectAtIndex:i] length];
    }
    
    // For length, it's simply the length of the line at index
    NSUInteger length = [[fileLines objectAtIndex:index] length];
    
    location += index;
    
    return NSMakeRange(location, length);
}

-(void)indentLineAtIndex:(NSUInteger)index
{
    NSString* indentedLineAtIndex = [[GNTextGeometry tabString] stringByAppendingString:[self lineAtIndex:index]];
    fileText = [fileText stringByReplacingCharactersInRange:[self rangeOfLineAtIndex:index]
                                                 withString:indentedLineAtIndex];
    
    [self textChanged];
    
    if(index == [insertionPointManager insertionLine])
    {
        [insertionPointManager incrementInsertionByLength:[GNTextGeometry tabWidth]
                                                isNewLine:NO];
    }
    else if(index < [insertionPointManager insertionLine])
    {
        // Increment the insertion index
        [insertionPointManager setInsertionIndex:[insertionPointManager insertionIndex] + [GNTextGeometry tabWidth]];
    }
}

-(void)unindentLineAtIndex:(NSUInteger)index
{
    NSString* lineAtIndex = [self lineAtIndex:index];
    NSRange rangeOfTab = [lineAtIndex rangeOfString:[GNTextGeometry tabString]];
    if((rangeOfTab.location != NSNotFound) && (rangeOfTab.location == 0))
    {
        // There is a tab on this line, and it's at the very beginning of the line
        NSString* unindentedLineAtIndex = [lineAtIndex stringByReplacingCharactersInRange:NSMakeRange(0, [GNTextGeometry tabWidth])
                                                                               withString:@""];
        fileText = [fileText stringByReplacingCharactersInRange:[self rangeOfLineAtIndex:index]
                                                     withString:unindentedLineAtIndex];
        
        [self textChanged];
        
        if(index == [insertionPointManager insertionLine])
        {
            [insertionPointManager decrementByCount:[GNTextGeometry tabWidth]];
        }
        else if(index < [insertionPointManager insertionLine])
        {
            [insertionPointManager setInsertionIndex:[insertionPointManager insertionIndex] - [GNTextGeometry tabWidth]];
        }
    }
}

-(void)refreshFileLines
{
    fileLines = [NSMutableArray arrayWithArray:[fileText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
}

-(NSString*)currentWord
{
    return [fileText substringWithRange:[self rangeOfCurrentWord]];
}

-(NSRange)rangeOfCurrentWord
{        
    NSMutableCharacterSet* stoppingCharacters = [NSMutableCharacterSet whitespaceCharacterSet];
    [stoppingCharacters formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    [stoppingCharacters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
    [stoppingCharacters formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
    
    NSInteger location = [insertionPointManager absoluteInsertionIndex];
    
    if([fileText isEqualToString:@""])
    {
        // No current word
        return NSMakeRange(0, 0);
    }
    
    if(location > 0)
    {
        location--;
    }
    
    while(![stoppingCharacters characterIsMember:[fileText characterAtIndex:location]])
    {
        if(location > 0)
        {
            location--;
        }
        else
        {
            break;
        }
    }
    
    if((location < [fileText length] - 1) && (location != 0))
    {
        location++;
    }
    
    if([stoppingCharacters characterIsMember:[fileText characterAtIndex:location]])
    {
        // No current word
        return NSMakeRange(0, 0);
    }
    
    NSInteger length = 0;
    while(location + length < [fileText length] && ![stoppingCharacters characterIsMember:[fileText characterAtIndex:location+length]])
    {
        length++;
    }
    
    return NSMakeRange(location, length);
}

-(void)insertTabAtInsertionPoint
{
    NSRange rangeOfInsertionLine = [self rangeOfLineAtIndex:[insertionPointManager insertionLine]];
    rangeOfInsertionLine.location += [insertionPointManager insertionIndexInLine];
    rangeOfInsertionLine.length -= [insertionPointManager insertionIndexInLine];
        
    NSString* indentedPartialLine = [[GNTextGeometry tabString] stringByAppendingString:[fileText substringWithRange:rangeOfInsertionLine]];
    
    fileText = [fileText stringByReplacingCharactersInRange:rangeOfInsertionLine withString:indentedPartialLine];
    
    [self textChanged];
    [insertionPointManager incrementInsertionByLength:[GNTextGeometry tabWidth]
                                            isNewLine:NO];
}

-(void)cleanUp
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark GNInsertionPointManagerDelegate methods
-(NSUInteger)characterCountToLineAtIndex:(NSUInteger)lineIndex
{
    NSUInteger characterCount = 0;
    for(NSUInteger i = 0; i < lineIndex; i++)
    {
        characterCount += [[self lineAtIndex:i] length];
    }
    return characterCount;
}

@end
