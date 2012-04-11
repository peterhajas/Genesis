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


#import "GNProjectBrowserViewController.h"
#import "GNDirectoryViewController.h"
#import "GNApplicationSettingsViewController.h"

@implementation GNProjectBrowserViewController

-(IBAction)addProjectButtonPressed:(id)sender
{
    GNNewProjectViewController* newProjectViewController = [[GNNewProjectViewController alloc] initWithNibName:@"GNNewProjectViewController"
                                                                                                        bundle:[NSBundle mainBundle]];
    [newProjectViewController setDelegate:self];
    [self presentModalViewController:newProjectViewController animated:YES];
}

-(IBAction)editButtonPressed:(id)sender
{
    // Shift the table view into edit mode
    [tableViewController toggleEditing];
    
    // Change the sender to the correct style for this context
    
    if(tableViewController.editing)
    {
        [sender setTitle:@"Done"];
        [sender setStyle:UIBarButtonItemStyleDone];
    }
    else
    {
        [sender setTitle:@"Edit"];
        [sender setStyle:UIBarButtonItemStylePlain];
    }
}

-(IBAction)settingsButtonPushed:(id)sender
{
    GNApplicationSettingsViewController* applicationSettingsViewController = [[GNApplicationSettingsViewController alloc] initWithNibName:@"GNApplicationSettingsViewController"
                                                                                                                                   bundle:[NSBundle mainBundle]];
    
    [self presentModalViewController:applicationSettingsViewController animated:YES];
}

-(void)didSelectProject:(GNProject*)project
{
    // Create a new GNDirectoryViewController for this project, and push it onto the stack
    GNDirectoryViewController* directoryViewController = [[GNDirectoryViewController alloc] initWithBackingPath:[project valueForKey:@"name"] 
                                                                                        andNavigationController:[self navigationController]];
    [[self navigationController] pushViewController:directoryViewController animated:YES];
}

#pragma mark - GNNewProjectViewControllerDelegate methods
-(void)didCreateProjectWithName:(NSString *)name
{
    NSArray* allProjects = [tableViewController allProjects];
    NSMutableArray* allProjectNames = [[NSMutableArray alloc] init];
    for(GNProject* project in allProjects)
    {
        [allProjectNames addObject:[project valueForKey:@"name"]];
    }
    
    NSUInteger indexOfProjectName = [allProjectNames indexOfObject:name];
    NSIndexPath* indexPathForProject = [NSIndexPath indexPathForRow:indexOfProjectName inSection:0];
    
    // Select this project in the tableview
    [tableView selectRowAtIndexPath:indexPathForProject
                           animated:YES
                     scrollPosition:UITableViewScrollPositionMiddle];
    [tableViewController tableView:tableView didSelectRowAtIndexPath:indexPathForProject];
}

#pragma mark - View transitions
-(void)dismissModalViewControllerAnimated:(BOOL)animated
{
    [tableView reloadData];
    [super dismissModalViewControllerAnimated:animated];
}

#pragma mark - View lifecycle

-(id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        tableViewController = [[GNProjectBrowserTableViewController alloc] initWithStyle:UITableViewStylePlain];
        [tableViewController setDelegate:self];
        
        [self setTitle:@"Projects"];        
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
        
    // Create our "add" and "edit" buttons for projects
    UIBarButtonItem* addButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProjectButtonPressed:)];
    UIBarButtonItem* editButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
    
    [[self navigationItem] setRightBarButtonItem:addButtonItem animated:YES];
    [[self navigationItem] setLeftBarButtonItem:editButtonItem animated:YES];
    
    // Set the table view controller tableview to our IBOutlet'd one
    
    [tableViewController setTableView:tableView];
    [tableView reloadData];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
