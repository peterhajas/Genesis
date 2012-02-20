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
-(NSString*)escapeHTMLString:(NSString*)html;

@property(nonatomic,retain) id<GNSyntaxHighlighterDelegate> delegate;

@end
