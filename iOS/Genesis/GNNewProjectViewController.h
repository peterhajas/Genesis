//
//  GNNewProjectViewController.h
//  Genesis
//
//  Created by Peter Hajas on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GNNewProjectViewControllerDelegate

-(void)didCreateProjectWithName:(NSString*)name;

@end

@interface GNNewProjectViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UITextField* projectNameField;
    id<GNNewProjectViewControllerDelegate> delegate;
}

-(IBAction)cancelPushed:(id)sender;

@property(nonatomic,retain) id<GNNewProjectViewControllerDelegate> delegate;

@end
