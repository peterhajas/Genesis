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

#import "GNApplicationSettingsViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@implementation GNApplicationSettingsViewController

-(void)viewDidLoad
{
    // Set enabled/disabled state of the button
    // based on Dropbox linked status
    
    if(![[DBSession sharedSession] isLinked])
    {
        [linkToDropboxButton setEnabled:YES];
    }
    else
    {
        [linkToDropboxButton setEnabled:NO];
    }
}

-(IBAction)donePushed:(id)sender
{
    [[self presentingViewController] dismissModalViewControllerAnimated:YES];
}

-(IBAction)linkToDropboxPushed:(id)sender
{
    // If the DBSession isn't linked, link it
    if(![[DBSession sharedSession] isLinked])
    {
        [[DBSession sharedSession] link];
    }
}

@end
