//
//  GNFileEditorViewController.m
//  Genesis
//
//  Created by Peter Hajas on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNFileEditorViewController.h"

@implementation GNFileEditorViewController

-(id)initWithAbsolutePath:(NSString*)path;
{
    self = [super initWithNibName:@"GNFileEditorViewController" bundle:[NSBundle mainBundle]];
    if(self)
    {
        absolutePath = [NSString stringWithString:path];
        [self setTitle:[absolutePath lastPathComponent]];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString* fileContents = [NSString stringWithContentsOfFile:absolutePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    
    NSURL* bundleURL = [[NSBundle mainBundle] bundleURL];
    
    NSString* html = [NSString stringWithFormat:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"shell" 
                                                                                                                   ofType:@"html"]
                                                                          encoding:NSUTF8StringEncoding
                                                                             error:nil]];
    
    [webView loadHTMLString:html
                    baseURL:bundleURL];
    
    [webView stringByEvaluatingJavaScriptFromString:@""];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
