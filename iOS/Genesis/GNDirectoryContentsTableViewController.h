//
//  GNDirectoryContentsTableViewController.h
//  Genesis
//
//  Created by Peter Hajas on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GNDirectoryContentsTableViewController : UITableViewController
{
    NSString* backingPath;
}

-(id)initWithBackingPath:(NSString*)path;
-(NSArray*)contentsForPath;
-(NSArray*)filesForPath;
-(NSArray*)directoriesForPath;

@end
