//
//  GNDirectoryViewController.m
//  Genesis
//
//  Created by Peter Hajas on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNDirectoryViewController.h"

@implementation GNDirectoryViewController

-(id)initWithBackingPath:(NSString *)path
{
    self = [super initWithNibName:@"GNDirectoryViewController" bundle:[NSBundle mainBundle]];
    if(self)
    {
        [self setTitle:path];
        backingPath = [NSString stringWithString:path];
        directoryContentsTableViewController = [[GNDirectoryContentsTableViewController alloc] initWithBackingPath:path];
    }
    return self;
}

#pragma mark - View lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the table view controller tableview to our IBOutlet'd one
    [directoryContentsTableViewController setTableView:tableView];
    [tableView reloadData];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
