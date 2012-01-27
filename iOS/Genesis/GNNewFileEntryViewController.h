//
//  GNNewFileEntryViewController.h
//  Genesis
//
//  Created by Peter Hajas on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GNNewFileEntryViewControllerDelegate

-(void)didCreateFileEntry;

@end

@interface GNNewFileEntryViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UISegmentedControl* fileEntityTypeSegmentedControl;
    IBOutlet UITextField* fileEntityName;
    IBOutlet UINavigationItem* titleNavigationItem;
    
    NSString* backingPath;
    
    id<GNNewFileEntryViewControllerDelegate> delegate;
}

-(id)initWithBackingPath:(NSString*)path;
-(IBAction)segmentedControlChanged:(id)sender;
-(IBAction)cancelPushed:(id)sender;

@property(nonatomic,retain) id<GNNewFileEntryViewControllerDelegate> delegate;

@end
