//
//  GNTextViewController.h
//  Genesis
//
//  Created by Peter Hajas on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GNTextView.h"

@interface GNTextViewController : UIViewController
{
    IBOutlet GNTextView* textView;
    NSString* backingPath;
}

-(id)initWithBackingPath:(NSString*)path;

@end
