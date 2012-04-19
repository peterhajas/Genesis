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

#import "GNTextTableViewDataSource.h"
#import "GNTextTableViewCell.h"

@implementation GNTextTableViewDataSource

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

#pragma mark UITableViewDataSource Table View Configuration

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    GNTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kGNTextTableViewCellReuseIdentifier];
    if(cell)
    {
        // Recompute our cell's ivars
        [cell setLineNumber:[indexPath row]];
    }
    else
    {
        cell = [[GNTextTableViewCell alloc] initWithFileRepresentation:fileRepresentation
                                                              andIndex:[indexPath row]];
    }
    
    [cell setFileRepresentation:fileRepresentation];
    
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

#pragma mark UITableViewDataSource Table View Insertion / Deletion

-(void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    return YES;
}

#pragma mark UITableViewDataSource Reordering Table Rows

-(BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    return NO;
}

-(void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath
{
    
}

@end
