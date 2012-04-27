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

#import "GNDirectoryViewController.h"
#import "GNTextViewController.h"
#import "GNNetworkNotificationKeys.h"

@implementation GNDirectoryViewController

-(id)initWithBackingPath:(NSString *)path andNavigationController:(UINavigationController *)navigationController
{
    self = [super initWithNibName:@"GNDirectoryViewController" bundle:[NSBundle mainBundle]];
    if(self)
    {
        [self setTitle:[path lastPathComponent]];
        backingPath = [NSString stringWithString:path];
        directoryContentsTableViewController = [[GNDirectoryContentsTableViewController alloc] initWithBackingPath:path];
        [directoryContentsTableViewController setDelegate:self];
        pushableNavigationController = navigationController;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadFilesForNotification:)
                                                     name:GNFilesForProjectNotification
                                                   object:nil];
    }
    return self;
}

-(void)reloadFilesForNotification:(NSNotification *)notification
{
    [tableView reloadData];
}

#pragma mark - Navigation bar buttons

-(IBAction)addFilesystemEntryButtonPressed:(id)sender
{
    GNNewFileEntryViewController* newFileEntryViewController = [[GNNewFileEntryViewController alloc] initWithBackingPath:backingPath];
    [newFileEntryViewController setDelegate:self];
    [self presentModalViewController:newFileEntryViewController animated:YES];
}


#pragma mark - GNDirectoryContentsTableViewControllerDelegate methods

-(void)didSelectDirectoryWithRelativePath:(NSString*)relativePath
{
    // Create a new GNDirectoryViewController for this path, and then browse to it
    GNDirectoryViewController* directoryViewController = [[GNDirectoryViewController alloc] initWithBackingPath:[backingPath stringByAppendingPathComponent:relativePath]
                                                                                        andNavigationController:pushableNavigationController];
    
    [pushableNavigationController pushViewController:directoryViewController animated:YES];
}

-(void)didSelectFileWithRelativePath:(NSString*)relativePath
{
    GNTextViewController* textViewController = [[GNTextViewController alloc] initWithBackingPath:[backingPath stringByAppendingPathComponent:relativePath]];
    
    [pushableNavigationController pushViewController:textViewController animated:YES];
}

#pragma mark - View lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the table view controller tableview to our IBOutlet'd one
    [directoryContentsTableViewController setTableView:tableView];
    [tableView reloadData];
    
    // Create our "add" button for files / folders
    UIBarButtonItem* addButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFilesystemEntryButtonPressed:)];
    
    [[self navigationItem] setRightBarButtonItem:addButtonItem animated:YES];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)didCreateFileEntry
{
    [tableView reloadData];
}

@end
