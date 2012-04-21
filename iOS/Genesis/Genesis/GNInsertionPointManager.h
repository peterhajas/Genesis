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

@protocol GNInsertionPointAnnouncerDelegate <NSObject>

-(void)insertionPointDidChange;

@end

@protocol GNInsertionPointManagerDelegate <NSObject>

-(NSUInteger)characterCountToLineAtIndex:(NSUInteger)lineIndex;

@end

@interface GNInsertionPointManager : NSObject
{
    NSUInteger insertionIndex;
    NSUInteger insertionIndexInLine;
    NSUInteger insertionLine;
    
    NSUInteger stringLength;
    
    NSObject<GNInsertionPointAnnouncerDelegate>* announcerDelegate;
    NSObject<GNInsertionPointManagerDelegate>* delegate;
}

-(void)incrementInsertionByLength:(NSUInteger)length isNewLine:(BOOL)isNewLine;

/*
 Two potential cases:
 1: Regular delete in the middle of a line
 2: Delete past the beginning of a line
 */

-(void)decrement;
-(void)decrementByCount:(NSUInteger)count;
-(void)decrementToPreviousLineWithOldLineLength:(NSUInteger)oldLineLength newLineLength:(NSUInteger)newLineLength;

-(BOOL)insertionIsAtStartOfFile;
-(void)setInsertionToLineAtIndex:(NSUInteger)lineIndex characterIndexInLine:(NSUInteger)characterIndex;

@property(readwrite) NSUInteger insertionIndex;
@property(readwrite) NSUInteger insertionIndexInLine;
@property(readwrite) NSUInteger insertionLine;
@property(readonly)  NSUInteger absoluteInsertionIndex; // insertionIndex + insertionLine, for appropriate newline management
@property(readwrite) NSUInteger stringLength;

@property(nonatomic,retain) NSObject<GNInsertionPointAnnouncerDelegate>* announcerDelegate;
@property(nonatomic,retain) NSObject<GNInsertionPointManagerDelegate>* delegate;

@end
