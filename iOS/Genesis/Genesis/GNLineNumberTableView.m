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

#import "GNLineNumberTableView.h"
#import "GNTextTableViewDelegate.h"

@implementation GNLineNumberTableView

@synthesize scrollDelegate;

-(id)initWithFileRepresentation:(GNFileRepresentation*)representation height:(CGFloat)height
{
    self = [super initWithFrame:CGRectMake(0,
                                           0,
                                           kGNLineNumberTableViewWidth,
                                           height) 
                          style:UITableViewStylePlain];
    if(self)
    {
        // Set the file representation
        fileRepresentation = representation;
        
        dataSource = [[GNLineNumberTableViewDataSource alloc] initWithFileRepresentation:fileRepresentation];
        [self setDataSource:dataSource];
        [self setDelegate:self];
        
        [self setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    }
    
    return self;
}

#pragma mark UITableViewDelegate methods

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Create an instance of GNTextTableViewDelegate, and pass the method through
    GNTextTableViewDelegate* passthroughDestinationDelegate = [[GNTextTableViewDelegate alloc] init];
    return [passthroughDestinationDelegate tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark UIScrollViewDelegate methods

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [scrollDelegate scrollViewDidScroll:scrollView];
}

@end