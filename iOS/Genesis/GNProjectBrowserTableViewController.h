//
//  GNProjectBrowserTableViewManager.h
//  Genesis
//
//  Created by Peter Hajas on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GNProject.h"

@protocol GNProjectBrowserTableViewControllerDelegate

-(void)didSelectProject:(GNProject*)project;

@end

@interface GNProjectBrowserTableViewController : UITableViewController
{
    id<GNProjectBrowserTableViewControllerDelegate> delegate;
}

@property (nonatomic, retain) id<GNProjectBrowserTableViewControllerDelegate> delegate;

-(void)toggleEditing;
-(NSArray*)allProjects;

@end
