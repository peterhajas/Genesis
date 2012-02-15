//
//  GNSyntaxHighlighter.m
//  Genesis
//
//  Created by Peter Hajas on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNSyntaxHighlighter.h"

@implementation GNSyntaxHighlighter

@synthesize delegate;

-(void)highlightText:(NSString*)text
{
    // Load base.html
    
    NSString* base = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"base" 
                                                                                        ofType:@"html"]
                                               encoding:NSUTF8StringEncoding
                                                  error:nil];
    
    // Replace ___code___ with our text
    
    NSString* html = [base stringByReplacingOccurrencesOfString:@"___code___" withString:text];
    
    // Load this HTML
    
    [webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
}

-(UIColor*)colorForCSSFunction:(NSString*)css
{
    // Color is formatted like this: rgb(RRR, GGG, BBB)
    
    // Cut off rgb(
    NSString* delimitedColor = [css substringFromIndex:3];
    
    // Cut off the )
    delimitedColor = [delimitedColor substringToIndex:[delimitedColor length]-1];
    
    NSArray* colorComponents = [delimitedColor componentsSeparatedByString:@", "];
    
    return [UIColor colorWithRed:[[colorComponents objectAtIndex:0] floatValue] / 255.0
                           green:[[colorComponents objectAtIndex:1] floatValue] / 255.0
                            blue:[[colorComponents objectAtIndex:2] floatValue] / 255.0
                           alpha:1.0];
}

-(NSString*)sanitizeHTMLEscapes:(NSString*)dirty
{
    NSString* clean = [dirty copy];
    
    // Sanitize HTML escapes
    clean = [clean stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&cent;" withString:@"¢"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&pound;" withString:@"£"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&yen;" withString:@"¥"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&euro;" withString:@"€"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&sect;" withString:@"§"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&copy;" withString:@"©"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&reg;" withString:@"®"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&trade;" withString:@"™"];
    
    clean = [clean stringByReplacingOccurrencesOfString:@"&lt" withString:@"<"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&gt" withString:@">"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&amp" withString:@"&"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&cent" withString:@"¢"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&pound" withString:@"£"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&yen" withString:@"¥"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&euro" withString:@"€"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&sect" withString:@"§"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&copy" withString:@"©"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&reg" withString:@"®"];
    clean = [clean stringByReplacingOccurrencesOfString:@"&trade" withString:@"™"];
    
    return clean;
}

-(id)initWithDelegate:(id<GNSyntaxHighlighterDelegate>)_delegate;
{
    self = [super initWithFrame:CGRectMake(0, 0, 1.0, 1.0)];
    if(self)
    {
        // Create our webview
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 1.0, 1.0)];
        [webView setDelegate:self];
        [self addSubview:webView];
        
        delegate = _delegate;
    }
    
    return self;
}

-(void)webViewDidFinishLoad:(UIWebView *)asdf
{
    // Awesome, we loaded!
    
    // Execute our javascript function for delimited highlighted code
    
    NSString* highlightedCode = [webView stringByEvaluatingJavaScriptFromString:@"highlightedCode()"];
    
    // Create the NSMutableAttributedString we'll stick our highlighted information into
    
    NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] init];
    
    // Split the highlightedCode into elements based on :::\n, our delimiter for each line
    
    NSArray* highlightedElements = [highlightedCode componentsSeparatedByString:@":::\n"];
    
    for(NSUInteger i = 0; i < [highlightedElements count]; i++)
    {
        // Split up the element based on our delimiter, ;;;
        
        NSString* element = [highlightedElements objectAtIndex:i];
        NSArray* elementComponents = [element componentsSeparatedByString:@";;;"];
        
        if([elementComponents count] == 2)
        {
            NSString* code = [elementComponents objectAtIndex:0];
            code = [self sanitizeHTMLEscapes:code];
            
            UIColor* color = [self colorForCSSFunction:[elementComponents objectAtIndex:1]];
            
            NSMutableAttributedString* highlightedElement = [[NSMutableAttributedString alloc] initWithString:code];
            [highlightedElement addAttribute:(NSString*)kCTForegroundColorAttributeName
                                       value:(id)[color CGColor]
                                       range:[code rangeOfString:code]];
            
            [attributedString appendAttributedString:highlightedElement];
        }
    }
    
    // Let our delegate know that we're done highlighting
    
    [delegate didHighlightText:attributedString];
}

-(BOOL)webView:(UIWebView *)asdf shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

@end
