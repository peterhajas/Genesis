//
//  GNDirectoryContentsTableViewCell.h
//  Genesis
//
//  Created by Peter Hajas on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    kGNDirectoryContentsTableViewCellTypeDirectory = 0,
    kGNDirectoryContentsTableViewCellTypeFile = 1
} kGNDirectoryContentsTableViewCellType;

@interface GNDirectoryContentsTableViewCell : UITableViewCell

-(id)initWithType:(kGNDirectoryContentsTableViewCellType)type;

@end
