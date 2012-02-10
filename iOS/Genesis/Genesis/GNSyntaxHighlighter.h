//
//  GNSyntaxHighlighter.h
//  Genesis
//
//  Created by Peter Hajas on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GNSyntaxHighlighter : NSObject <UIWebViewDelegate>
{
    UIWebView* webView;
}

-(NSString*)htmlWithEmbeddedCode:(NSString*)code;
-(NSAttributedString*)highlightedStringForString:(NSString*)string;

@property(nonatomic, retain) UIWebView* webView;

@end
