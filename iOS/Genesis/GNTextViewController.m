//
//  GNTextViewController.m
//  Genesis
//
//  Created by Peter Hajas on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNTextViewController.h"

@implementation GNTextViewController

-(id)initWithBackingPath:(NSString*)path;
{
    self = [super initWithNibName:@"GNTextViewController" bundle:[NSBundle mainBundle]];
    if(self)
    {
        backingPath = path;
        [self setTitle:[backingPath lastPathComponent]];
    }
    return self;
}

#pragma mark View lifecycle

-(void)viewDidLoad
{
    // Load the string in the file, and show it
    
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]; //TODO: error checking on this!
    NSString* absolutePath = [documentPath stringByAppendingPathComponent:backingPath];
    
    NSString* fileContents = [NSString stringWithContentsOfFile:absolutePath encoding:NSUTF8StringEncoding error:nil]; //TODO: error checking on this!
    [textView setText:fileContents];
}

@end
