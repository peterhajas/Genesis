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

#define kGNTextTableViewCellReuseIdentifier @"kGNTextTableViewCellReuseIdentifier"

#import <UIKit/UIKit.h>
#import "GNFileRepresentation.h"
#import "GNSyntaxHighlighter.h"

@interface GNTextTableViewCell : UITableViewCell <GNSyntaxHighlighterDelegate>
{
    NSString* representedLineText;
    NSAttributedString* attributedLine;
    
    GNFileRepresentation* fileRepresentation;
    
    GNSyntaxHighlighter* syntaxHighlighter;
    
    UITapGestureRecognizer* tapGestureRecognizer;
    
    CTLineRef line;
    NSUInteger lineNumber;
    
    CGContextRef staleContext;
}

-(id)initWithLine:(NSString*)lineText atIndex:(NSUInteger)index;

@property (nonatomic, retain) GNFileRepresentation* fileRepresentation;

@end
