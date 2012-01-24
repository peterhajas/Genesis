//
//  GNProjectBrowserViewController.h
//  Genesis
//
//  Created by Peter Hajas on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GNProjectBrowserTableViewDataSource.h"

@interface GNProjectBrowserViewController : UIViewController
{
    IBOutlet UITableView* tableView;
    GNProjectBrowserTableViewDataSource* dataSource;
}

-(IBAction)addProjectButtonPressed:(id)sender;

@end
