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

#import "GNTextTableViewCell.h"
#import "GNLineNumberTableView.h"

@implementation GNTextTableViewCell

@synthesize fileRepresentation;
@synthesize lineNumber;

-(id)initWithFileRepresentation:(GNFileRepresentation*)representation andIndex:(NSUInteger)index
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kGNTextTableViewCellReuseIdentifier];
    if(self)
    {
        textContainerScrollView = [[UIScrollView alloc] initWithFrame:[self frame]];
        [textContainerScrollView setContentSize:[self frame].size];
        [self addSubview:textContainerScrollView];
        
        [textContainerScrollView setDelegate:self];
        
        textLineView = [[GNTextLineView alloc] initWithFileRepresentation:representation
                                                               lineNumber:index
                                                                    frame:[self frame]
                                                        andSizingDelegate:self];
        
        [textContainerScrollView addSubview:textLineView];
        
        lineNumber = index;
        
        // Create our tap gesture recognizer
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(handleTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];
        
        // Create our swipe gesture recognizers
        swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(didSwipeRight:)];
        [swipeRightGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [swipeRightGestureRecognizer setNumberOfTouchesRequired:2];
        [self addGestureRecognizer:swipeRightGestureRecognizer];
        
        swipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(didSwipeLeft:)];
        [swipeLeftGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
        [swipeLeftGestureRecognizer setNumberOfTouchesRequired:2];
        [self addGestureRecognizer:swipeLeftGestureRecognizer];
        
        // Set our autoresizing mask
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [textContainerScrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        // Subscribe to insertion point changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textChanged:)
                                                     name:GNTextChangedNotification
                                                   object:nil];
    }
    
    return self;
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    [self resetScrollPosition];
}

-(void)didMoveToSuperview
{
    [textContainerScrollView setFrame:CGRectMake(0,
                                                 0,
                                                 [self frame].size.width,
                                                 [self frame].size.height)];
    [textContainerScrollView setContentSize:CGSizeMake([textContainerScrollView contentSize].width,
                                                       [self frame].size.height)];
    CGRect textLineViewFrame = [textLineView frame];
    [textLineView setFrame:CGRectMake(textLineViewFrame.origin.x,
                                      textLineViewFrame.origin.y,
                                      [self frame].size.width,
                                      [self frame].size.height)];
    
    // Set the scrollview content offset    
    CGFloat horizontalOffset = [[fileRepresentation horizontalOffsetManager] horizontalOffsetForLineAtIndex:lineNumber];
    
    [textContainerScrollView setContentOffset:CGPointMake(horizontalOffset,
                                                          [textContainerScrollView contentOffset].y)];
}

-(void)handleTap:(UITapGestureRecognizer*)sender
{
    if([sender state] == UIGestureRecognizerStateEnded)
    {
        CGPoint touchLocation = [sender locationInView:self];
        touchLocation.x += [textContainerScrollView contentOffset].x;
        CFIndex indexIntoString = [textLineView indexForTappedPoint:touchLocation];
                
        [[fileRepresentation insertionPointManager] setInsertionToLineAtIndex:lineNumber
                                                         characterIndexInLine:indexIntoString];
        
        CGFloat horizontalOffset = [textContainerScrollView contentOffset].x;
        NSNumber* horizontalOffsetNumber = [NSNumber numberWithFloat:horizontalOffset];
        [[NSNotificationCenter defaultCenter] postNotificationName:GNHorizontalOffsetChangedNotification
                                                            object:horizontalOffsetNumber];
        
        [self resignFirstResponder];
    }
}

-(void)didSwipeRight:(UISwipeGestureRecognizer*)sender
{
    [[fileRepresentation fileText] indentLineAtIndex:lineNumber];
}

-(void)didSwipeLeft:(UISwipeGestureRecognizer*)sender
{
    [[fileRepresentation fileText] unindentLineAtIndex:lineNumber];
}

-(void)resetScrollPosition
{
    if([[fileRepresentation insertionPointManager] insertionLine] != lineNumber)
    {
        [textContainerScrollView setContentOffset:CGPointMake(0, 0)
                                         animated:YES];
    }
}

-(void)setLineNumber:(NSUInteger)line
{
    // Change the index of us and our line view
    lineNumber = line;
    [textLineView setLineNumber:line];
}

-(void)textChanged:(id)object
{
    // If the insertion point is on our line
    if([[fileRepresentation insertionPointManager] insertionLine] == lineNumber)
    {
        /*
         We need to scroll our scrollview to meet the new insertion point of
         our file representation.
        */
        
        if([textLineView line] != NULL)
        {
            CGRect lineBounds = [textLineView frame];
            
            CGFloat horizontalOffset = lineBounds.size.width + lineBounds.origin.x;
                    
            if(horizontalOffset > [self frame].size.width * (0.8))
            {
                CGFloat newHorizontalPosition = (horizontalOffset - [self frame].size.width * (0.8));
                [textContainerScrollView setContentOffset:CGPointMake(newHorizontalPosition,
                                                                      [textContainerScrollView contentOffset].y)];
            }
        }
    }
    // Otherwise, reset our scroll position
    else
    {
        [self resetScrollPosition];
    }
}

#pragma mark GNTextLineViewSizingDelegate methods

-(void)requiresWidth:(CGFloat)width
{
    [textContainerScrollView setContentSize:CGSizeMake(width,
                                                       [textContainerScrollView contentSize].height)];
}

#pragma mark UIScrollViewDelegate methods

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat horizontalOffset = [scrollView contentOffset].x;
    if(lineNumber == [[fileRepresentation insertionPointManager] insertionLine])
    {
        NSNumber* horizontalOffsetNumber = [NSNumber numberWithFloat:horizontalOffset];
        [[NSNotificationCenter defaultCenter] postNotificationName:GNHorizontalOffsetChangedNotification
                                                            object:horizontalOffsetNumber];
    }
    
    [[fileRepresentation horizontalOffsetManager] setHorizontalOffset:horizontalOffset
                                                       forLineAtIndex:lineNumber];
}

@end
