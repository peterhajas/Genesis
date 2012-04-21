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

#import "GNAttributedFileText.h"
#import "GNTextAttributer.h"
#import "GNTextGeometry.h"

@implementation GNAttributedFileText

-(id)initWithText:(NSString*)text fileText:(GNFileText*)fileText andFileExtension:(NSString*)fileExtension
{
    self = [super init];
    if(self)
    {
        file = fileText;
        
        attributedFileContents = [[NSAttributedString alloc] initWithString:[fileText fileText]];
        languageDictionary = [GNTextAttributer languageDictionaryForExtension:fileExtension];
    }
    return self;
}

-(void)updateWithText:(NSString*)text
{
    attributedFileContents = [GNTextAttributer attributedStringForText:text
                                                withLanguageDictionary:languageDictionary];
    
    attributedFileContents = [GNTextGeometry attributedStringWithDefaultFontApplied:attributedFileContents];
}

-(NSAttributedString*)attributedLineAtIndex:(NSUInteger)index
{
    NSRange lineRange = [[file fileText] rangeOfString:[file lineAtIndex:index]];
    if(lineRange.location == NSNotFound)
    {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    return [attributedFileContents attributedSubstringFromRange:lineRange];
}

@end
