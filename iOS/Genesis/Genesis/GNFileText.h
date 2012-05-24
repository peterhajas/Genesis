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

@protocol GNFileTextDelegate <NSObject>

-(void)textWillChange;
-(void)textDidChange;
-(void)horizontalOffsetManagerShouldInsertLineAtIndex:(NSUInteger)index;
-(void)horizontalOffsetManagerShouldRemoveLineAtIndex:(NSUInteger)index;

@end

@interface GNFileText : NSObject <GNHorizontalOffsetManagerDelegate,
                                  GNInsertionPointManagerDelegate>
{
    NSString* fileText;
    NSMutableArray* fileLines;
    
    GNInsertionPointManager* insertionPointManager;
    GNHorizontalOffsetManager* horizontalOffsetManager;
    
    NSObject<GNFileTextDelegate>* fileTextDelegate;
}

-(id)initWithData:(NSData*)contents;

// Text
-(BOOL)hasText;
-(NSUInteger)textLength;
-(void)insertText:(NSString*)text;
-(void)insertText:(NSString *)text indexDelta:(NSInteger)delta;
-(NSString*)textInRange:(NSRange)range;
-(void)replaceTextInRange:(NSRange)range withText:(NSString*)text;
-(void)deleteBackwards;
-(void)textChanged;

// Lines
-(NSString*)currentLine;
-(NSUInteger)lineCount;
-(NSUInteger)lineIndexForStringIndex:(NSUInteger)index;
-(NSString*)lineAtIndex:(NSUInteger)index;
-(NSUInteger)indexInLineForAbsoluteStringIndex:(NSUInteger)index;
-(NSString*)lineAtIndex:(NSUInteger)lineIndex toIndexInLine:(NSUInteger)index;
-(NSString*)lineToInsertionPoint;
-(NSRange)rangeOfLineAtIndex:(NSUInteger)index;
-(NSRange)rangeOfLineAtStringIndex:(NSUInteger)stringIndex;
-(void)indentLineAtIndex:(NSUInteger)index;
-(void)unindentLineAtIndex:(NSUInteger)index;

// Current word
-(NSString*)currentWord;
-(NSRange)rangeOfCurrentWord;

// NSNotificationCenter management
-(void)cleanUp;

@property(nonatomic, retain) NSString* fileText;
@property(readonly) NSArray* fileLines;

@property(nonatomic,retain) GNInsertionPointManager* insertionPointManager;
@property(nonatomic,retain) GNHorizontalOffsetManager* horizontalOffsetManager;

@property(nonatomic,retain) NSObject<GNFileTextDelegate>* fileTextDelegate;

@end
