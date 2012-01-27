//
//  GNNewFileEntryViewController.m
//  Genesis
//
//  Created by Peter Hajas on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNNewFileEntryViewController.h"

@implementation GNNewFileEntryViewController

@synthesize delegate;

-(id)initWithBackingPath:(NSString*)path
{
    self = [super initWithNibName:@"GNNewFileEntryViewController"
                           bundle:[NSBundle mainBundle]];
    if(self)
    {
        backingPath = [NSString stringWithString:path];
    }
    
    return self;
}

-(IBAction)segmentedControlChanged:(id)sender
{
    // If the segmented control is at the first position, then we're in file mode
    if([(UISegmentedControl*)sender selectedSegmentIndex] == 0)
    {
        [titleNavigationItem setTitle:@"New File"];
    }
    // If it's at the second, we're in folder mode
    else if([(UISegmentedControl*)sender selectedSegmentIndex] == 1)
    {
        [titleNavigationItem setTitle:@"New Folder"];
    }
}

-(IBAction)cancelPushed:(id)sender
{
    // Dismiss us!
    [[self presentingViewController] dismissModalViewControllerAnimated:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // If the text of the text field isn't blank
    if(![[textField text] isEqualToString:@""])
    {
        // Let's make sure there isn't a file in the backingPath with this same name
        NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* directoryPath = [documentPath stringByAppendingPathComponent:backingPath];

        NSArray* filesInBackingPath = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath 
                                                                                           error:nil] 
                                       sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]; //TODO: error checking on this!
        
        // Determine if this is a file we're checking for, or a folder
        
        NSString* entityPath = [directoryPath stringByAppendingPathComponent:[textField text]];
        
        BOOL isDirectory = NO;
        BOOL fileExists = NO;
        BOOL entityExists = NO;
        
        fileExists = [[NSFileManager defaultManager] fileExistsAtPath:entityPath isDirectory:&isDirectory];
        
        // Check if there's a file with this particular name
        if([fileEntityTypeSegmentedControl selectedSegmentIndex] == 0)
        {
            entityExists = !isDirectory && fileExists;
        }
        // Check if there's a folder with this particular name
        else if([fileEntityTypeSegmentedControl selectedSegmentIndex] == 1)
        {
            entityExists = isDirectory && fileExists;
        }

        
        if([filesInBackingPath containsObject:[textField text]] && entityExists)
        {
            // If this file entity already exists in this directory, present a UIAlertView
            UIAlertView* duplicateFileAlertView = [[UIAlertView alloc] initWithTitle:@"That already exists!"
                                                                             message:[NSString stringWithFormat:@"\"%@\" already exists in this directory. If you'd like to overwrite it, delete it first.", [textField text]]
                                                                            delegate:self
                                                                   cancelButtonTitle:@"Do not create."
                                                                   otherButtonTitles:nil];
            
            [duplicateFileAlertView show];
        }
        else
        {
            // Ok, excellent! The file doesn't already exist. Let's create it!
            // If the segmented control is at the first position, then we're in file mode
            if([fileEntityTypeSegmentedControl selectedSegmentIndex] == 0)
            {
                // Create the file
                
                [[NSFileManager defaultManager] createFileAtPath:entityPath
                                                        contents:nil
                                                      attributes:nil];
            }
            // If it's at the second, we're in folder mode
            else if([fileEntityTypeSegmentedControl selectedSegmentIndex] == 1)
            {
                // Create the directory
                
                [[NSFileManager defaultManager] createDirectoryAtPath:entityPath
                                          withIntermediateDirectories:NO
                                                           attributes:nil
                                                                error:nil];
            }
            
            [delegate didCreateFileEntry];
            
            [[self presentingViewController] dismissModalViewControllerAnimated:YES];
            
            return YES;
        }
    }
    
    return YES;
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
