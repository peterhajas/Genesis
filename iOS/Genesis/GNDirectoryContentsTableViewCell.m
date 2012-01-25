//
//  GNDirectoryContentsTableViewCell.m
//  Genesis
//
//  Created by Peter Hajas on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNDirectoryContentsTableViewCell.h"

@implementation GNDirectoryContentsTableViewCell

-(id)initWithType:(kGNDirectoryContentsTableViewCellType)type
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"kGNDirectoryCOntentsTableViewCell"];
    if(self)
    {
        if(type == kGNDirectoryContentsTableViewCellTypeDirectory)
        {
            [[self detailTextLabel] setText:@"Directory"];
        }
        else if(type == kGNDirectoryContentsTableViewCellTypeFile)
        {
            [[self detailTextLabel] setText:@"File"];
        }
    }
    return self;
}

@end
