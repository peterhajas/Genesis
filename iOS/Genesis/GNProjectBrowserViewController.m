//
//  GNProjectBrowserViewController.m
//  Genesis
//
//  Created by Peter Hajas on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNProjectBrowserViewController.h"
#import "GNNewProjectViewController.h"

@implementation GNProjectBrowserViewController

-(IBAction)addProjectButtonPressed:(id)sender
{
    GNNewProjectViewController* newProjectViewController = [[GNNewProjectViewController alloc] initWithNibName:@"GNNewProjectViewController"
                                                                                                        bundle:[NSBundle mainBundle]];
    [self presentModalViewController:newProjectViewController animated:YES];
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
        dataSource = [[GNProjectBrowserTableViewDataSource alloc] init];
        [self setTitle:@"Projects"];        
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [tableView setDataSource:dataSource];
    
    // Create our "add" button for creating a new project
    UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProjectButtonPressed:)];
    
    [[self navigationItem] setRightBarButtonItem:barButtonItem animated:YES];
    
    [tableView reloadData];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
