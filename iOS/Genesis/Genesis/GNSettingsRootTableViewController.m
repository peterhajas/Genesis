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

#import "GNSettingsRootTableViewController.h"
#import "GNTextGeometry.h"
#import "GNFontCell.h"

@implementation GNSettingsRootTableViewController

@synthesize delegate;

-(id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if(self)
    {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem* done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                          target:self
                                                                          action:@selector(donePushed:)];
    
    [[self navigationItem] setRightBarButtonItem:done];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)donePushed:(id)sender
{
    [delegate dismiss];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if([indexPath section] == 0)
    {
        // It's an appearance setting
        switch([indexPath row])
        {
                // It's the font row
            case 0:
                return [[GNFontCell alloc] initWithFontWithName:[[GNSharedSettings sharedSettings] valueForKey:GNSettingsFontFaceKey]
                                                           size:[GNTextGeometry fontSize]];
                // It's the theme row
            case 1:
            {
                UITableViewCell* cell = [[UITableViewCell alloc] init];
                [[cell textLabel] setText:[[GNSharedSettings sharedSettings] valueForKey:GNSettingsThemeKey]];
                return cell;
            }
        }
    }
    
    NSLog(@"Can't find a cell for settings at section %d row %d", [indexPath section], [indexPath row]);
    return [[UITableViewCell alloc] init];
}

-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:
            return @"Appearance";            
        default:
            return @"Settings Section";
    }
}


#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    
}

@end
