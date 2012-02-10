//
//  GNSyntaxHighlighter.m
//  Genesis
//
//  Created by Peter Hajas on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNSyntaxHighlighter.h"

@implementation GNSyntaxHighlighter

@synthesize webView;

-(id)init
{
    self = [super init];
    if(self)
    {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
        [webView setDelegate:self];
    }
    
    return self;
}

-(NSString*)htmlWithEmbeddedCode:(NSString*)code
{
    NSString* htmlString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"base" 
                                                                                              ofType:@"html"]
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"___code___" withString:code];
    return htmlString;
}

-(NSAttributedString*)highlightedStringForString:(NSString*)string
{
    [webView setNeedsDisplayInRect:CGRectMake(0, 0, 500, 500)];
    //NSString* htmlString = [GNSyntaxHighlighter htmlWithEmbeddedCode:string];
    
    [webView loadHTMLString:[self htmlWithEmbeddedCode:string]
                    baseURL:[[NSBundle mainBundle] bundleURL]];
    
    return nil;
}

-(void)webViewDidFinishLoad:(UIWebView *)asdf
{
    NSString* style = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"prettify" 
                                                                                         ofType:@".css"] 
                                                                                       encoding:NSUTF8StringEncoding error:nil];
    
    NSString* code = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"codeblock\").innerHTML;"];
    
    DTCSSStylesheet* styleSheet = [[DTCSSStylesheet alloc] initWithStyleBlock:style];
    
    NSDictionary* __autoreleasing options = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:styleSheet] forKeys:[NSArray arrayWithObject:DTDefaultStyleSheet]];
    
    NSAttributedString* demo = [[NSAttributedString alloc] initWithHTML:[code dataUsingEncoding:NSUTF8StringEncoding]
                                                     documentAttributes:&options];
    
    NSLog(@"attr str: %@", demo);
    
    NSDictionary* attributes = [demo attributesAtIndex:0 effectiveRange:NULL];
    
    CFTypeRef font = CTFontCopyAttribute((CTFontRef)CFDictionaryGetValue((__bridge CFDictionaryRef)attributes, CFSTR("NSFont")), CFSTR("kCTForegroundColorAttributeName"));
    
    
    
    
    
}

-(BOOL)webView:(UIWebView *)asdf shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

@end
