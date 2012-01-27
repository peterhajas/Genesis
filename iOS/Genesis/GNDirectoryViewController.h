//
//  GNDirectoryViewController.h
//  Genesis
//
//  Created by Peter Hajas on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GNProject.h"
#import "GNDirectoryContentsTableViewController.h"
#import "GNNewFileEntryViewController.h"

@interface GNDirectoryViewController : UIViewController <GNDirectoryContentsTableViewControllerDelegate,
                                                         GNNewFileEntryViewControllerDelegate>
{
    IBOutlet UITableView* tableView;
    GNDirectoryContentsTableViewController* directoryContentsTableViewController;
    NSString* backingPath;
    UINavigationController* pushableNavigationController;
}

-(id)initWithBackingPath:(NSString*)path andNavigationController:(UINavigationController*)navigationController;
-(IBAction)addFilesystemEntryButtonPressed:(id)sender;

@end
