//
//  GNDirectoryContentsTableViewController.m
//  Genesis
//
//  Created by Peter Hajas on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNDirectoryContentsTableViewController.h"
#import "GNDirectoryContentsTableViewCell.h"

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
        relativePath = [[self directoriesForPath] objectAtIndex:indexPath.row];
        [delegate didSelectDirectoryWithRelativePath:relativePath];
    }
    else if(indexPath.section == 1)
    {
        // They selected a file
        relativePath = [[self filesForPath] objectAtIndex:indexPath.row];
        [delegate didSelectFileWithRelativePath:relativePath];
    }
    else
    {
        NSLog(@"Undefined section for GNDirectoryContentsTableViewController, in directory %@", backingPath);
    }
}

#pragma mark - Table View Data Source

-(NSArray*)contentsForPath
{
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]; //TODO: error checking on this!
    NSString* absolutePath = [documentPath stringByAppendingPathComponent:backingPath];
    
    return [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:absolutePath error:nil] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

-(NSArray*)filesForPath
{
    NSArray* allContents = [self contentsForPath];
    NSMutableArray* allFiles = [[NSMutableArray alloc] init];
    
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]; //TODO: error checking on this!
    NSString* directoryPath = [documentPath stringByAppendingPathComponent:backingPath];
    
    for(NSString* directoryEntry in allContents)
    {
        NSString* absoluteEntryPath = [directoryPath stringByAppendingPathComponent:directoryEntry];
        BOOL isDirectory = NO;

        [[NSFileManager defaultManager] fileExistsAtPath:absoluteEntryPath isDirectory:&isDirectory];
        if(!isDirectory)
        {
            [allFiles addObject:directoryEntry];
        }
    }
    
    return [NSArray arrayWithArray:allFiles];
}

-(NSArray*)directoriesForPath
{
    NSArray* allContents = [self contentsForPath];
    NSMutableArray* allDirectories = [[NSMutableArray alloc] init];
    
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]; //TODO: error checking on this!
    NSString* directoryPath = [documentPath stringByAppendingPathComponent:backingPath];
    
    for(NSString* directoryEntry in allContents)
    {
        NSString* absoluteEntryPath = [directoryPath stringByAppendingPathComponent:directoryEntry];
        BOOL isDirectory = NO;
        
        [[NSFileManager defaultManager] fileExistsAtPath:absoluteEntryPath isDirectory:&isDirectory];
        if(isDirectory)
        {
            [allDirectories addObject:directoryEntry];
        }
    }
    
    return [NSArray arrayWithArray:allDirectories];
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    GNDirectoryContentsTableViewCell* tableViewCell;
    NSArray* relevantEntries = nil;
    if(indexPath.section == 0)
    {
        // Return a directory table view cell
        tableViewCell = [[GNDirectoryContentsTableViewCell alloc] initWithType:kGNDirectoryContentsTableViewCellTypeDirectory];
        relevantEntries = [self directoriesForPath];
    }
    else if(indexPath.section == 1)
    {
        // Return a file table view cell
        tableViewCell = [[GNDirectoryContentsTableViewCell alloc] initWithType:kGNDirectoryContentsTableViewCellTypeFile];
        relevantEntries = [self filesForPath];
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
    if(section == 0)
    {
        return [[self directoriesForPath] count];
    }
    else if(section == 1)
    {
        return [[self filesForPath] count];
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
        
        NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]; //TODO: error checking on this!
        NSString* directoryPath = [documentPath stringByAppendingPathComponent:backingPath];

        NSString* entityPath = @"";
        
        if(indexPath.section == 0)
        {
            // It's a directory
            entityPath = [directoryPath stringByAppendingPathComponent:[[self directoriesForPath] objectAtIndex:indexPath.row]];
        }
        else if(indexPath.section == 1)
        {
            // It's a file
            entityPath = [directoryPath stringByAppendingPathComponent:[[self filesForPath] objectAtIndex:indexPath.row]];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:entityPath error:nil]; //TODO: error checking on this!
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
