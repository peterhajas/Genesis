//
//  GNFileEditorViewController.h
//  Genesis
//
//  Created by Peter Hajas on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GNFileEditorViewController : UIViewController
{
    NSString* absolutePath;
    IBOutlet UIWebView* webView;
}

-(id)initWithAbsolutePath:(NSString*)path;

@end
