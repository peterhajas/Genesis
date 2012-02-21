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

#import "GNDirectoryContentsTableViewController.h"
#import "GNDirectoryContentsTableViewCell.h"
#import "GNFileManager.h"

@implementation GNDirectoryContentsTableViewController

@synthesize delegate;

-(id)initWithBackingPath:(NSString*)path
{
    self = [super init];
    if(self)
    {
        backingPath = [NSString stringWithString:path];
    }
    return self;
}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString* relativePath = nil;
    
    if(indexPath.section == 0)
    {
        // They selected a directory
        relativePath = [[GNFileManager directoryDirectoryContentsAtRelativePath:backingPath] objectAtIndex:indexPath.row];
        [delegate didSelectDirectoryWithRelativePath:relativePath];
    }
    else if(indexPath.section == 1)
    {
        // They selected a file
        relativePath = [[GNFileManager directoryFileContentsAtRelativePath:backingPath] objectAtIndex:indexPath.row];
        [delegate didSelectFileWithRelativePath:relativePath];
    }
    else
    {
        NSLog(@"Undefined section for GNDirectoryContentsTableViewController, in directory %@", backingPath);
    }
}

#pragma mark - Table View Data Source

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    GNDirectoryContentsTableViewCell* tableViewCell;
    NSArray* relevantEntries = nil;
    if(indexPath.section == 0)
    {
        // Return a directory table view cell
        tableViewCell = [[GNDirectoryContentsTableViewCell alloc] initWithType:kGNDirectoryContentsTableViewCellTypeDirectory];
        relevantEntries = [GNFileManager directoryDirectoryContentsAtRelativePath:backingPath];
    }
    else if(indexPath.section == 1)
    {
        // Return a file table view cell
        tableViewCell = [[GNDirectoryContentsTableViewCell alloc] initWithType:kGNDirectoryContentsTableViewCellTypeFile];
        relevantEntries = [GNFileManager directoryFileContentsAtRelativePath:backingPath];
    }
    else
    {
        NSLog(@"Undefined section for GNDirectoryContentsTableViewController, in directory %@", backingPath);
        return nil;
    }
    
    [[tableViewCell textLabel] setText:[relevantEntries objectAtIndex:indexPath.row]];
    return tableViewCell;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) // Directory entries
    {
        return [[GNFileManager directoryDirectoryContentsAtRelativePath:backingPath] count];
    }
    else if(section == 1) // File entries
    {
        return [[GNFileManager directoryFileContentsAtRelativePath:backingPath] count];
    }
    else
    {
        return 0;
    }
}

-(void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Get the path of the item they deleted
        
        NSString* entityPath = @"";
        
        if(indexPath.section == 0)
        {
            // It's a directory
            entityPath = [backingPath stringByAppendingPathComponent:[[GNFileManager directoryDirectoryContentsAtRelativePath:backingPath] objectAtIndex:indexPath.row]];
        }
        else if(indexPath.section == 1)
        {
            // It's a file
            entityPath = [backingPath stringByAppendingPathComponent:[[GNFileManager directoryFileContentsAtRelativePath:backingPath] objectAtIndex:indexPath.row]];
        }
        
        [GNFileManager removeContentAtRelativePath:entityPath];
        
        [tableView reloadData];
    }
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        return @"Directories";
    }
    else if(section == 1)
    {
        return @"Files";
    }
    else
    {
        NSLog(@"Undefined section for GNDirectoryContentsTableViewController, in directory %@", backingPath);
        return nil;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

@end
