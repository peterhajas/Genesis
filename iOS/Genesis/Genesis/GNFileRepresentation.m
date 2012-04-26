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

@synthesize fileText;
@synthesize horizontalOffsetManager;
@synthesize insertionPointManager;
@synthesize attributedFileText;
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
        
        fileText = [[GNFileText alloc] initWithData:contents];
        
        horizontalOffsetManager = [[GNHorizontalOffsetManager alloc] init];
        [horizontalOffsetManager setDelegate:fileText];
        
        insertionPointManager = [[GNInsertionPointManager alloc] init];
        [insertionPointManager setDelegate:fileText];
        [insertionPointManager setAnnouncerDelegate:self];
        
        attributedFileText = [[GNAttributedFileText alloc] initWithText:[fileText fileText]
                                                               fileText:fileText
                                                       andFileExtension:[path pathExtension]];
        
        autoCompleteDictionary = [[GNAutocompleteDictionary alloc] init];
        
        [fileText setInsertionPointManager:insertionPointManager];
        [fileText setHorizontalOffsetManager:horizontalOffsetManager];
        [fileText setFileTextDelegate:self];
        
        [horizontalOffsetManager clearHorizontalOffsets];
        
        [self textDidChange];
    }
    return self;
}

-(void)textDidChange
{
    [insertionPointManager setStringLength:[[fileText fileText] length]];
    
    [GNFileManager setFileContentsAtRelativePath:relativePath
                                       toContent:[[fileText fileText] dataUsingEncoding:NSUTF8StringEncoding]];
        
    [attributedFileText updateWithText:[fileText fileText]];
    
    [autoCompleteDictionary addTextToBackingStore:[fileText fileLines]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GNTextChangedNotification
                                                        object:self];
}

-(void)insertionPointDidChange
{
    [[NSNotificationCenter defaultCenter] postNotificationName:GNInsertionPointChangedNotification
                                                        object:self];
}

-(void)horizontalOffsetManagerShouldInsertLineAtIndex:(NSUInteger)index
{
    [horizontalOffsetManager insertLineWithEmptyHorizontalOffsetAtIndex:index];
}
-(void)horizontalOffsetManagerShouldRemoveLineAtIndex:(NSUInteger)index
{
    [horizontalOffsetManager removeLineWithEmptyHorizontalOffsetAtIndex:index];
}

-(void)cleanUp
{
    [fileText cleanUp];
}

#pragma mark File extension property
-(NSString*)fileExtension
{
    return [relativePath pathExtension];
}

@end
