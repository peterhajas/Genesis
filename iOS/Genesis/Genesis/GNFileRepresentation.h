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

#import <Foundation/Foundation.h>
#import "GNHorizontalOffsetManager.h"
#import "GNInsertionPointManager.h"
#import "GNAutocompleteDictionary.h"

@interface GNFileRepresentation : NSObject <GNHorizontalOffsetManagerDelegate,
                                            GNInsertionPointManagerDelegate>
{
    NSString* relativePath;
    NSString* fileContents;
    NSMutableArray* fileLines;
    
    NSAttributedString* attributedFileContents;
    NSDictionary* languageDictionary; 
    
    NSMutableArray* lineHorizontalOffsets;
    
    GNHorizontalOffsetManager* horizontalOffsetManager;
    GNInsertionPointManager* insertionPointManager;
    GNAutocompleteDictionary* autoCompleteDictionary;
}

-(id)initWithRelativePath:(NSString*)path;

-(NSUInteger)lineCount;

-(NSString*)lineAtIndex:(NSUInteger)index;
-(void)insertLineWithText:(NSString*)text afterLineAtIndex:(NSUInteger)index;
-(void)removeLineAtIndex:(NSUInteger)index;

-(void)moveLineAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

-(NSAttributedString*)attributedLineAtIndex:(NSUInteger)index;

-(BOOL)hasText;
-(void)insertText:(NSString*)text;
-(void)deleteBackwards;

-(NSString*)lineToInsertionPoint;

-(void)textChanged;

-(NSString*)currentLine;

-(NSString*)currentWord;
-(NSRange)rangeOfCurrentWord;

-(void)insertText:(NSString *)text indexDelta:(NSInteger)delta;
-(void)replaceTextInRange:(NSRange)range withText:(NSString*)text;

@property(readonly) NSString* fileExtension;

@property(readonly) GNHorizontalOffsetManager* horizontalOffsetManager;
@property(readonly) GNInsertionPointManager* insertionPointManager;
@property(readonly) GNAutocompleteDictionary* autoCompleteDictionary;

@end
