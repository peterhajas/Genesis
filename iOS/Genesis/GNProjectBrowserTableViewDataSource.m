//
//  GNProjectBrowserTableViewDataSource.m
//  Genesis
//
//  Created by Peter Hajas on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNProjectBrowserTableViewDataSource.h"
#import "GNAppDelegate.h"

@implementation GNProjectBrowserTableViewDataSource

#pragma mark - Table View Data Source

-(id)init
{
    self = [super init];
    return self;
}

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

@end
