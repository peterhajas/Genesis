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
    
    insertionLine = lineIndex;
    
    if(insertionIndex + characterIndex < [fileContents length])
    {
        insertionIndex += characterIndex;
    
        insertionIndexInLine = characterIndex;
    }
        
    [self insertionPointChanged];
}

-(BOOL)hasText
{
    return [fileContents length] > 0;
}

-(void)insertText:(NSString*)text
{    
    if(![text isEqualToString:@"\n"])
    {
        if([fileContents isEqualToString:@""])
        {
            fileContents = [fileContents stringByAppendingString:text];
        }
        else
        {
            // Grab the text before and after the insertion point
            NSString* beforeInsertion = [fileContents substringToIndex:insertionIndex + insertionLine];
            NSString* afterInsertion = [fileContents substringFromIndex:insertionIndex + insertionLine];
            
            // Concatenate beforeInsertion + text + afterInsertion
            fileContents = [beforeInsertion stringByAppendingString:text];
            fileContents = [fileContents stringByAppendingString:afterInsertion];
        }
        
        [self textChanged];
        
        // Increment the insertion index by the length of text
        insertionIndex += [text length];
        insertionIndexInLine += [text length];
        [self insertionPointChanged];
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
        insertionIndexInLine--;
        [self insertionPointChanged];
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
        [self insertionPointChanged];
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
        [self insertionPointChanged];
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
    [self insertionPointChanged];
}

-(NSString*)lineToInsertionPoint
{
    if([[self currentLine] isEqualToString:@""])
    {
        return @"";
    }
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
    
    [autoCompleteDictionary addTextToBackingStore:fileLines];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kGNTextChanged"
                                                        object:self];
}

-(void)insertionPointChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kGNInsertionPointChanged"
                                                        object:self];
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
    return [fileContents substringWithRange:[self rangeOfCurrentWord]];
}

-(NSRange)rangeOfCurrentWord
{        
    NSMutableCharacterSet* stoppingCharacters = [NSMutableCharacterSet whitespaceCharacterSet];
    [stoppingCharacters formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    [stoppingCharacters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
    [stoppingCharacters formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
        
    NSInteger location = insertionIndex + insertionLine;
    
    if([fileContents isEqualToString:@""])
    {
        // No current word
        return NSMakeRange(0, 0);
    }
    
    if(location > 0)
    {
        location--;
    }
    
    while(![stoppingCharacters characterIsMember:[fileContents characterAtIndex:location]])
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
    
    if((location < [fileContents length] - 1) && (location != 0))
    {
        location++;
    }
    
    if([stoppingCharacters characterIsMember:[fileContents characterAtIndex:location]])
    {
        // No current word
        return NSMakeRange(0, 0);
    }
        
    NSInteger length = 0;
    while(location + length < [fileContents length] && ![stoppingCharacters characterIsMember:[fileContents characterAtIndex:location+length]])
    {
        length++;
    }
        
    return NSMakeRange(location, length);
}

-(void)insertText:(NSString *)text indexDelta:(NSInteger)delta
{
    [self insertText:text];
    insertionIndex += delta;
    [self insertionPointChangedShouldRecomputeIndices:YES];
}

-(void)replaceTextInRange:(NSRange)range withText:(NSString*)text
{
    // Compute how far we'll have to move our insertion index
    NSInteger delta = [text length] - range.length;
    
    fileContents = [fileContents stringByReplacingCharactersInRange:range withString:text];
    [self textChanged];
    insertionIndex += delta;
    [self insertionPointChangedShouldRecomputeIndices:YES];
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
