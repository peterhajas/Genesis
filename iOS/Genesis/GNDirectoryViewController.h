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

@interface GNDirectoryViewController : UIViewController
{
    IBOutlet UITableView* tableView;
    GNDirectoryContentsTableViewController* directoryContentsTableViewController;
    NSString* backingPath;
}

-(id)initWithBackingPath:(NSString*)path;

@end
