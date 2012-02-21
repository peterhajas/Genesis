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

#import "GNTextViewController.h"
#import "GNFileManager.h"

@implementation GNTextViewController

-(id)initWithBackingPath:(NSString*)path;
{
    self = [super initWithNibName:@"GNTextViewController" bundle:[NSBundle mainBundle]];
    if(self)
    {
        backingPath = path;
        [self setTitle:[backingPath lastPathComponent]];
    }
    return self;
}

#pragma mark View lifecycle

-(void)viewDidLoad
{
    // Load the string in the file, and show it
    
    NSString* fileContents = [[NSString alloc] initWithData:[GNFileManager fileContentsAtRelativePath:backingPath] 
                                                   encoding:NSUTF8StringEncoding];
    
    // If there's nothing in the file, populate it with an empty string
    
    if(fileContents == nil)
    {
        fileContents = @"";
    }
    
    [textView setText:fileContents];
}

#pragma mark Orientation changes

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

@end
