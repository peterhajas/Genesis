//
//  GNSyntaxHighlighter.h
//  Genesis
//
//  Created by Peter Hajas on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GNSyntaxHighlighterDelegate

-(void)didHighlightText:(NSAttributedString*)highlightedText;

@end

@interface GNSyntaxHighlighter : UIView <UIWebViewDelegate>
{
    UIWebView* webView;
    
    id<GNSyntaxHighlighterDelegate> delegate;
}

-(id)initWithDelegate:(id<GNSyntaxHighlighterDelegate>)_delegate;
-(void)highlightText:(NSString*)text;
-(UIColor*)colorForCSSFunction:(NSString*)css;
-(NSString*)sanitizeHTMLEscapes:(NSString*)dirty;

@property(nonatomic,retain) id<GNSyntaxHighlighterDelegate> delegate;

@end
