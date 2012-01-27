//
//  GNNewProjectViewController.m
//  Genesis
//
//  Created by Peter Hajas on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNNewProjectViewController.h"
#import "GNProjectBrowserViewController.h"
#import "GNAppDelegate.h"
#import "GNProject.h"

@implementation GNNewProjectViewController

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // If the text of the text field isn't blank
    if(![[textField text] isEqualToString:@""])
    {
        // TODO: Make sure this isn't a project that's already been made! Check for unique names!
        
        // Create the new project
        GNAppDelegate* appDelegate = (GNAppDelegate*)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext* managedObjectContext = [appDelegate managedObjectContext];
        
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GNProject" 
                                                             inManagedObjectContext:managedObjectContext];
        
        GNProject* project = [[GNProject alloc] initWithEntity:entityDescription
                                insertIntoManagedObjectContext:managedObjectContext];
        
        [managedObjectContext insertObject:project];
        
        // Set the project name
        [project setValue:[textField text] forKey:@"name"];
        
        // Save the context
        [appDelegate saveContext];
        
        // Create a new directory for this project
        NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]; //TODO: error checking on this!
        NSString* directoryPath = [documentPath stringByAppendingPathComponent:[textField text]];
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                  withIntermediateDirectories:NO 
                                                   attributes:nil 
                                                        error:nil];
        
        // TODO: Switch to this new project in the project browser
        
        // Dismiss us
        GNProjectBrowserViewController* projectBrowserViewController = (GNProjectBrowserViewController*)[(UINavigationController*)[self presentingViewController] topViewController];
        [projectBrowserViewController dismissModalViewControllerAnimated:YES];
        
    }
    
    return YES;
}

-(IBAction)cancelPushed:(id)sender;
{
    [[self presentingViewController] dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

-(void)viewDidLoad
{
    [projectNameField becomeFirstResponder];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
