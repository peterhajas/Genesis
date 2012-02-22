/* Copyright (c) 2012, individual contributors
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#import "GNNewFileEntryViewController.h"
#import "GNFileManager.h"

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
        NSString* entityPath = [backingPath stringByAppendingPathComponent:[textField text]];
        
        BOOL makingADirectory = NO;
        
        if([fileEntityTypeSegmentedControl selectedSegmentIndex] == 0)
        {
            makingADirectory = NO;
        }
        else if([fileEntityTypeSegmentedControl selectedSegmentIndex] == 1)
        {
            makingADirectory = YES;
        }
        
        // Let's make sure there isn't a file in the backingPath with this same name
        if([GNFileManager entryExistsAtRelativePath:entityPath isDirectory:makingADirectory])
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
            // Ok, excellent! The entity doesn't already exist. Let's create it!
            
            BOOL creationAttempt = [GNFileManager createFilesystemEntryAtRelativePath:backingPath
                                                                             withName:[textField text]
                                                                          isDirectory:makingADirectory];
            
            if(!creationAttempt)
            {
                // There was a problem!
                UIAlertView* issueCreatingEntityAlert = [[UIAlertView alloc] initWithTitle:@"Error creating filesystem entity"
                                                                                   message:@"Please see the Console."
                                                                                  delegate:self
                                                                         cancelButtonTitle:@"Bummer!"
                                                                         otherButtonTitles:nil];
                
                [issueCreatingEntityAlert show];
            }
            else
            {
                [delegate didCreateFileEntry];
            
                [[self presentingViewController] dismissModalViewControllerAnimated:YES];
            }
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
