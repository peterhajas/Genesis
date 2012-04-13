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

#import "GNTextView.h"
#import "GNTextTableViewCell.h"

@implementation GNTextView

-(id)initWithBackingPath:(NSString*)path andFrame:(CGRect)_frame
{
    self = [super initWithFrame:_frame];
    if(self)
    {
        // Set file representation
        fileRepresentation = [[GNFileRepresentation alloc] initWithRelativePath:path];
    }
    return self;
}

-(void)didMoveToSuperview
{
    // Create the text table view
    
    textTableView = [[GNTextTableView alloc] initWithFrame:CGRectMake([self frame].origin.x + kGNLineNumberTableViewWidth,
                                                                      [self frame].origin.y,
                                                                      [self frame].size.width - kGNLineNumberTableViewWidth,
                                                                      [self frame].size.height)];
    
    // Set up its data source
    textTableViewDataSource = [[GNTextTableViewDataSource alloc] initWithFileRepresentation:fileRepresentation];
    [textTableView setDataSource:textTableViewDataSource];
    
    // Set up its delegate
    textTableViewDelegate = [[GNTextTableViewDelegate alloc] init];
    [textTableViewDelegate setScrollDelegate:self];
    [textTableView setDelegate:textTableViewDelegate];
    
    // Add it as a subview
    
    [self addSubview:textTableView];
    
    // Create the text input manager view
    textInputManagerView = [[GNTextInputManagerView alloc] initWithFileRepresentation:fileRepresentation];
    [textInputManagerView setDelegate:self];
    
    // Add it as a subview
    
    [self addSubview:textInputManagerView];
    
    // Create the line number view
    
    lineNumberTableView = [[GNLineNumberTableView alloc] initWithFileRepresentation:fileRepresentation
                                                                             height:[self frame].size.height];
    [lineNumberTableView setScrollDelegate:self];
    
    // Add it as a subview
    [self addSubview:lineNumberTableView];
        
    [textTableView reloadData];
}

#pragma mark GNTextInputManagerViewDelegate methods

-(CGFloat)verticalScrollOffset
{
    return [textTableView contentOffset].y;
}

#pragma mark UIScrollViewDelegate methods

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Match the scroll position between textTableView and lineNumberTableView
    
    CGFloat verticalContentOffset = [scrollView contentOffset].y;
    UIScrollView* otherScrollView;
    
    if([scrollView isEqual:textTableView])
    {
        otherScrollView = lineNumberTableView;
    }
    else if([scrollView isEqual:lineNumberTableView])
    {
        otherScrollView = textTableView;
    }
    
    CGPoint otherScrollViewContentOffset = [otherScrollView contentOffset];
    [otherScrollView setContentOffset:CGPointMake(otherScrollViewContentOffset.x,
                                                  verticalContentOffset)];
    
    [textInputManagerView didScrollToVerticalOffset:verticalContentOffset];
    
    // Dismiss the keyboard
    [textInputManagerView resignFirstResponder];
    
    // Scroll any visible lines to their starting offsets
    NSArray* tableViewIndexPaths = [textTableView indexPathsForVisibleRows];
    for(NSIndexPath* tableViewCellPath in tableViewIndexPaths)
    {
        GNTextTableViewCell* cell = (GNTextTableViewCell*)[textTableView cellForRowAtIndexPath:tableViewCellPath];
        [cell resetScrollPosition];
    }
}

-(void)cleanUp
{
    [textTableView cleanUp];
    [textInputManagerView cleanUp];
    [lineNumberTableView cleanUp];
}

@end
