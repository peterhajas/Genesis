//
//  PHTextInnerView.h
//  TextViewTester
//
//  Created by Peter Hajas on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

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
