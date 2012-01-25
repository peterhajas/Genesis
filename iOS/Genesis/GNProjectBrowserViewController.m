//
//  GNProjectBrowserViewController.m
//  Genesis
//
//  Created by Peter Hajas on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNProjectBrowserViewController.h"
#import "GNNewProjectViewController.h"
#import "GNDirectoryViewController.h"

@implementation GNProjectBrowserViewController

-(IBAction)addProjectButtonPressed:(id)sender
{
    GNNewProjectViewController* newProjectViewController = [[GNNewProjectViewController alloc] initWithNibName:@"GNNewProjectViewController"
                                                                                                        bundle:[NSBundle mainBundle]];
    [self presentModalViewController:newProjectViewController animated:YES];
}

-(IBAction)editButtonPressed:(id)sender
{
    // Shift the table view into edit mode
    [tableViewController toggleEditing];
    
    // Change the sender to the correct style for this context
    
    if(tableViewController.editing)
    {
        [sender setTitle:@"Done"];
        [sender setStyle:UIBarButtonItemStyleDone];
    }
    else
    {
        [sender setTitle:@"Edit"];
        [sender setStyle:UIBarButtonItemStylePlain];
    }
}

-(void)didSelectProject:(GNProject*)project
{
    // Create a new GNDirectoryViewController for this project, and push it onto the stack
    GNDirectoryViewController* directoryViewController = [[GNDirectoryViewController alloc] initWithBackingPath:[project valueForKey:@"name"]];
    [[self navigationController] pushViewController:directoryViewController animated:YES];
}

#pragma mark - View transitions
-(void)dismissModalViewControllerAnimated:(BOOL)animated
{
    [tableView reloadData];
    [super dismissModalViewControllerAnimated:animated];
}

#pragma mark - View lifecycle

-(id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        tableViewController = [[GNProjectBrowserTableViewController alloc] initWithStyle:UITableViewStylePlain];
        [tableViewController setDelegate:self];
        
        [self setTitle:@"Projects"];        
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
        
    // Create our "add" and "edit" buttons for projects
    UIBarButtonItem* addButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProjectButtonPressed:)];
    UIBarButtonItem* editButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
    
    [[self navigationItem] setRightBarButtonItem:addButtonItem animated:YES];
    [[self navigationItem] setLeftBarButtonItem:editButtonItem animated:YES];
    
    // Set the table view controller tableview to our IBOutlet'd one
    
    [tableViewController setTableView:tableView];
    [tableView reloadData];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
