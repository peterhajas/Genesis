//
//  GNProjectBrowserTableViewDataSource.m
//  Genesis
//
//  Created by Peter Hajas on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNProjectBrowserTableViewController.h"
#import "GNAppDelegate.h"
#import "GNProject.h"

@implementation GNProjectBrowserTableViewController

-(id)init
{
    self = [super init];
    return self;
}

-(void)toggleEditing
{
    [self setEditing:!self.editing animated:YES];
}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"hi!");
}

#pragma mark - Table View Data Source

-(NSArray*)allProjects
{
    NSManagedObjectContext* managedObjectContext = [(GNAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectModel* managedObjectModel = [(GNAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectModel];
    
    NSFetchRequest* allProjectsFetchRequest = [managedObjectModel fetchRequestTemplateForName:@"GNAllProjectsFetchRequest"];
    
    NSArray* fetchResults = [managedObjectContext executeFetchRequest:allProjectsFetchRequest error:nil];
    
    return fetchResults;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Create a table view cell for this project
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:@"kGNProjectTableViewCell"];
    
    NSString* projectName = [[[self allProjects] objectAtIndex:indexPath.row] valueForKey:@"name"];
    
    [[cell textLabel] setText:projectName];
    
    return cell;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of projects in the managed object context
    return [[self allProjects] count];
}

-(void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        // They deleted a project
    
        // Find the matching project
        GNProject* project = [[self allProjects] objectAtIndex:indexPath.row];
        
        // Remove the project from the managed object context
        NSManagedObjectContext* managedObjectContext = [(GNAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
        [managedObjectContext deleteObject:project];
        
        // Reload data
        [tableView reloadData];
    }
}


@end
