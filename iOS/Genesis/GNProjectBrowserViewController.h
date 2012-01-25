//
//  GNProjectBrowserViewController.h
//  Genesis
//
//  Created by Peter Hajas on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GNProjectBrowserTableViewController.h"

@interface GNProjectBrowserViewController : UIViewController <GNProjectBrowserTableViewControllerDelegate>
{
    IBOutlet UITableView* tableView;
    GNProjectBrowserTableViewController* tableViewController;
}

-(IBAction)addProjectButtonPressed:(id)sender;
-(IBAction)editButtonPressed:(id)sender;

@end
