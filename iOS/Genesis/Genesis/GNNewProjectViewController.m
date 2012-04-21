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


#import "GNNewProjectViewController.h"
#import "GNProjectBrowserViewController.h"
#import "GNAppDelegate.h"
#import "GNProject.h"
#import "GNFileManager.h"

@implementation GNNewProjectViewController

@synthesize delegate;

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
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
        [GNFileManager createFilesystemEntryAtRelativePath:@""
                                                  withName:[textField text] 
                                               isDirectory:YES];
                
        // Dismiss us
        GNProjectBrowserViewController* projectBrowserViewController = (GNProjectBrowserViewController*)[(UINavigationController*)[self presentingViewController] topViewController];
        [projectBrowserViewController dismissModalViewControllerAnimated:YES];
        [delegate didCreateProjectWithName:[textField text]];
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
