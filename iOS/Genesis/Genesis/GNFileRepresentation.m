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

#import "GNFileRepresentation.h"
#import "GNFileManager.h"
#import "GNTextAttributer.h"
#import "GNTextGeometry.h"

@implementation GNFileRepresentation

@synthesize insertionIndex, insertionIndexInLine, insertionLine;
@synthesize autoCompleteDictionary;

-(id)initWithRelativePath:(NSString*)path
{
    self = [super init];
    if(self)
    {
        // Set relative path
        relativePath = path;
        
        // Grab file contents with GNFileManager
        NSData* contents = [GNFileManager fileContentsAtRelativePath:relativePath];
        if(contents)
        {
            fileContents = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
        }
        else
        {
            fileContents = @"";
        }
        
        autoCompleteDictionary = [[GNAutocompleteDictionary alloc] init];
        
        attributedFileContents = [[NSAttributedString alloc] initWithString:fileContents];
        languageDictionary = [GNTextAttributer languageDictionaryForExtension:[self fileExtension]];
        
        [self textChanged];
        
        lineHorizontalOffsets = [[NSMutableArray alloc] init];
        [self clearHorizontalOffsets];
        
        // Set insertion index and line to 0
        insertionIndex = 0;
        insertionLine = 0;
        insertionIndexInLine = 0;
    }
    return self;
}

-(void)refreshLineArray
{
    fileLines = [NSMutableArray arrayWithArray:[fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
}

-(NSUInteger)lineCount
{
    return [fileLines count];
}

-(NSString*)lineAtIndex:(NSUInteger)index
{
    return [fileLines objectAtIndex:index];
}

-(void)insertLineWithText:(NSString*)text afterLineAtIndex:(NSUInteger)index
{
    [fileLines insertObject:text atIndex:index];
}

-(void)removeLineAtIndex:(NSUInteger)index
{
    [fileLines removeObjectAtIndex:index];
}

-(void)moveLineAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    
}

-(NSAttributedString*)attributedLineAtIndex:(NSUInteger)index
{
    NSRange lineRange = [fileContents rangeOfString:[self lineAtIndex:index]];
    if(lineRange.location == NSNotFound)
    {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    return [attributedFileContents attributedSubstringFromRange:lineRange];
}

-(void)setInsertionToLineAtIndex:(NSUInteger)lineIndex characterIndexInLine:(NSUInteger)characterIndex
{
    insertionIndex = 0;
    
    for(NSUInteger i = 0; i < lineIndex; i++)
    {
        insertionIndex += [[fileLines objectAtIndex:i] length];
    }
    
    insertionIndex += characterIndex;
    
    insertionLine = lineIndex;
    insertionIndexInLine = characterIndex;
        
    [self insertionPointChangedShouldRecomputeIndices:NO];
}

-(BOOL)hasText
{
    return [fileContents length] > 0;
}

-(void)insertText:(NSString*)text
{    
    if(![text isEqualToString:@"\n"])
    {
        // Grab the text before and after the insertion point
        NSString* beforeInsertion = [fileContents substringToIndex:insertionIndex + insertionLine];
        NSString* afterInsertion = [fileContents substringFromIndex:insertionIndex + insertionLine];
        
        // Concatenate beforeInsertion + text + afterInsertion
        fileContents = [beforeInsertion stringByAppendingString:text];
        fileContents = [fileContents stringByAppendingString:afterInsertion];
        
        [self textChanged];
        
        // Increment the insertion index by the length of text
        insertionIndex += [text length];
        [self insertionPointChangedShouldRecomputeIndices:YES];
    }
    else
    {
        [self insertNewline];
    }
    
}

-(void)deleteBackwards
{
    if(insertionIndex == 0 && insertionLine == 0)
    {
        // Don't do anything. We can't move back.
        return;
    }
    
    // Grab the text before the insertion point minus 1 and the text after insertion
    NSString* beforeInsertion = [fileContents substringToIndex:insertionIndex - 1 + insertionLine];
    NSString* afterInsertion = [fileContents substringFromIndex:insertionIndex + insertionLine];
    
    // Set the new file contents
    fileContents = [beforeInsertion stringByAppendingString:afterInsertion];
    
    NSUInteger previousCurrentLineLength = [[self currentLine] length];
    
    [self textChanged];
    
    if(insertionIndexInLine > 1)
    {
        insertionIndex--;
        [self insertionPointChangedShouldRecomputeIndices:YES];
    }
    
    /*
     If insertionIndex in the current line is 1, we don't want to back up to
     the previous line, so we should manually compute the new insertionIndex
     and insertionIndexInLine.
     */
    
    else if(insertionIndexInLine == 1)
    {
        insertionIndex--;
        insertionIndexInLine--;
        [self insertionPointChangedShouldRecomputeIndices:NO];
    }
    
    /*
     If insertionIndexInLine is 0, then we compute the new insertion indices
     manually. insertionLine will be the previous line. insertionIndexInLine
     will be the length of the line we're moving to minus the length of the
     line that is being concatenated with it (previousCurrentLineLength).
     */
    
    else
    {
        [self removedLineAtIndex:insertionLine];
        
        insertionLine--;
        insertionIndexInLine = [[self currentLine] length] - previousCurrentLineLength;
        [self insertionPointChangedShouldRecomputeIndices:NO];
    }
}

-(void)insertNewline
{
    NSUInteger start, end;
    NSString* lineSubstring;
    NSString *leadingSpaces;
    NSRange leadingSpacesRange;
    
    [fileContents getLineStart:&start 
                           end:&end
                   contentsEnd:NULL
                      forRange:NSMakeRange(insertionIndex, [fileContents length] - insertionIndex)];
    
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
    NSString* beforeInsertion = [fileContents substringToIndex:insertionIndex + insertionLine];
    NSString* afterInsertion = [fileContents substringFromIndex:insertionIndex + insertionLine];
    
    // Concatenate beforeInsertion + textToInsert + afterInsertion
    fileContents = [beforeInsertion stringByAppendingString:textToInsert];
    fileContents = [fileContents stringByAppendingString:afterInsertion];
    
    [self textChanged];
    
    insertionIndex += [textToInsert length] - 1;
    insertionIndexInLine = [textToInsert length] - 1;
    insertionLine++;
    [self addedLineAtIndex:insertionLine];
    [self insertionPointChangedShouldRecomputeIndices:NO];
}

-(NSString*)lineToInsertionPoint
{
    return [[self currentLine] substringToIndex:insertionIndexInLine];
}

-(void)textChanged
{
    [GNFileManager setFileContentsAtRelativePath:relativePath
                                       toContent:[fileContents dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self refreshLineArray];
    
    attributedFileContents = [GNTextAttributer attributedStringForText:fileContents
                                                withLanguageDictionary:languageDictionary];
    
    attributedFileContents = [GNTextGeometry attributedStringWithDefaultFontApplied:attributedFileContents];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kGNTextChanged"
                                                        object:self];
    
    [autoCompleteDictionary addTextToBackingStore:fileLines];
}

-(void)insertionPointChangedShouldRecomputeIndices:(BOOL)shouldRecompute
{
    if(shouldRecompute)
    {
        // Recompute insertion line and insertion index in line
        
        NSInteger charactersUntilInsertionPoint = insertionIndex;
        
        insertionLine = 0;
        insertionIndexInLine = 0;
        
        for(NSString* line in fileLines)
        {
            NSInteger difference = charactersUntilInsertionPoint - [line length];
            
            if(difference <= 0)
            {
                insertionIndexInLine = charactersUntilInsertionPoint;
                
                break;
            }
            else
            {
                charactersUntilInsertionPoint-=[line length];
            }
            
            insertionLine += 1;
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kGNInsertionPointChanged"
                                                        object:self];
    
    // Test the current word stuff
    NSLog(@"our current word is: %@", [self currentWord]);
}

-(CGFloat)horizontalOffsetForLineAtIndex:(NSUInteger)index
{
    if(index < [lineHorizontalOffsets count])
    {
        return [[lineHorizontalOffsets objectAtIndex:index] floatValue];
    }
    return 0.0;
}


-(NSString*)currentLine
{
    return [fileLines objectAtIndex:insertionLine];
}

-(NSString*)currentWord
{
    return [[self currentLine] substringWithRange:[self rangeOfCurrentWordInCurrentLine]];
}

-(NSRange)rangeOfCurrentWordInCurrentLine
{
    /*
     We need to grow out from the insertionIndexInLine until we hit a stopping character
     That's how we'll know if we hit the bounds of our word. We'll need a left and right
     bound marker, and we'll continue to grow them.
     */
        
    NSMutableCharacterSet* stoppingCharacters = [NSMutableCharacterSet whitespaceCharacterSet];
    [stoppingCharacters formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    
    NSUInteger leftBound, rightBound;
    leftBound = rightBound = insertionIndexInLine;
    
    NSString* currentLine = [self currentLine];
    
    // If the string is empty, return a zero length range
    if([currentLine isEqualToString:@""])
    {
        return NSMakeRange(0, 0);
    }
    
    if(leftBound >= [currentLine length])
    {
        leftBound--;
    }
    
    if(rightBound > [currentLine length])
    {
        rightBound--;
    }
    
    // Find our left bound
    while(leftBound > 0)
    {
        // Check behind left bound, to see if we can move it over
        unichar behindLeftBound = [currentLine characterAtIndex:leftBound-1];
        if(![stoppingCharacters characterIsMember:behindLeftBound])
        {
            // Good! Decrement leftBound
            leftBound--;
        }
        else
        {
            // Even better! This is our right boundary
            break;
        }
    }
    
    // Find our right bound
    while(rightBound < [currentLine length] - 2)
    {
        if(rightBound + 1 >= [currentLine length])
        {
            break;
        }
        // Check ahead of right bound, to see if we can move it over
        unichar aheadRightBound = [currentLine characterAtIndex:rightBound+1];
        if(![stoppingCharacters characterIsMember:aheadRightBound])
        {
            // Cool! Increment rightBound
            rightBound++;
        }
        else
        {
            // Awesome, we've found our right boundary
            rightBound++;
            break;
        }
    }
    
    // Now, we have our left and right bounds.
    // The location of our range is simply leftBound.
    // The length of our range is rightBound - leftBound
    
    return NSMakeRange(leftBound, rightBound - leftBound);
}

#pragma mark Horizontal Offset Management

-(void)setHorizontalOffset:(CGFloat)scrollOffset forLineAtIndex:(NSUInteger)index
{
    NSNumber* newHorizontalOffset = [NSNumber numberWithFloat:scrollOffset];
    [lineHorizontalOffsets replaceObjectAtIndex:index withObject:newHorizontalOffset];
}

-(void)addedLineAtIndex:(NSUInteger)index
{
    [lineHorizontalOffsets insertObject:[NSNumber numberWithFloat:0.0]
                                atIndex:index];
}

-(void)removedLineAtIndex:(NSUInteger)index
{
    [lineHorizontalOffsets removeObjectAtIndex:index];
}


-(void)clearHorizontalOffsets
{
    for(NSUInteger i = 0; i < [fileLines count]; i++)
    {
        [lineHorizontalOffsets addObject:[NSNumber numberWithFloat:0.0]];
    }
}

#pragma mark File extension property
-(NSString*)fileExtension
{
    return [relativePath pathExtension];
}

@end
