//
//  GNDirectoryContentsTableViewController.h
//  Genesis
//
//  Created by Peter Hajas on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GNDirectoryContentsTableViewControllerDelegate

-(void)didSelectDirectoryWithRelativePath:(NSString*)relativePath;
-(void)didSelectFileWithRelativePath:(NSString*)relativePath;

@end

@interface GNDirectoryContentsTableViewController : UITableViewController
{
    NSString* backingPath;
    id<GNDirectoryContentsTableViewControllerDelegate> delegate;
}

-(id)initWithBackingPath:(NSString*)path;
-(NSArray*)contentsForPath;
-(NSArray*)filesForPath;
-(NSArray*)directoriesForPath;

@property (nonatomic, retain) id<GNDirectoryContentsTableViewControllerDelegate> delegate;

@end
