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

#import "GNLineNumberTableViewDataSource.h"

@implementation GNLineNumberTableViewDataSource

-(id)initWithFileRepresentation:(GNFileRepresentation*)representation
{
    self = [super init];
    if(self)
    {
        // Set the file representation
        fileRepresentation = representation;
    }
    
    return self;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:kGNLineNumberTableViewCellReuseIdentifier];
    [[cell textLabel] setText:[NSString stringWithFormat:@"%d",[indexPath row] + 1]];
    [[cell textLabel] setFont:[UIFont fontWithName:DEFAULT_FONT_FAMILY size:10]];
    [[cell textLabel] setTextAlignment:UITextAlignmentRight];
    
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    // Currently 1, just the text
    return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of lines in the file representation
    return [[fileRepresentation fileText] lineCount];
}

@end
