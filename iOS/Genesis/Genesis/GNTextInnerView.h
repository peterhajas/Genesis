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

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "GNTextRange.h"
#import "GNTextCaretView.h"

@protocol GNTextInnerViewContainerProtocol <NSObject>

-(void)requireSize:(CGSize)size;

@end

@interface GNTextInnerView : UIView <UITextInput,
                                     UITextInputTraits>

{
    NSString* shownText;
    CFMutableAttributedStringRef attributedString;
    CTFramesetterRef frameSetter;
    CTFrameRef frame;
    
    GNTextCaretView* caretView;
    NSUInteger textCaretIndex;
    
    UITapGestureRecognizer* tapGestureReognizer;
    
    CGContextRef staleContext;
    
    UITextInputStringTokenizer* stringTokenizer;
    id<UITextInputDelegate> textInputDelegate;
    
    GNTextRange* selectedTextRange;
    
    id<GNTextInnerViewContainerProtocol> containerDelegate;
}

-(void)fitFrameToText;
-(CTLineRef)closestLineToPoint:(CGPoint)point inRange:(GNTextRange*)range;
-(void)moveCaretToIndex:(NSUInteger)index;

-(void)redrawText;
-(void)evaluateFramesetter;
-(void)plotText;

-(void)tapInView:(id)sender;

-(CGRect)rectForCharacterAtIndex:(NSUInteger)index;

@property(nonatomic,retain) NSString* shownText;
@property(nonatomic,retain) id<GNTextInnerViewContainerProtocol> containerDelegate;

@end
