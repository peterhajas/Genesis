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

#import "GNTMBundleAttributeNameTransformer.h"
#import <Foundation/NSAttributedString.h>
#import "GNTextGeometry.h"
#include <stdlib.h>

@implementation GNTMBundleAttributeNameTransformer

#define colorAttributes [NSArray arrayWithObjects:(NSString*)kCTForegroundColorAttributeName, nil]
#define fontAttributes [NSArray arrayWithObjects:(NSString*)kCTFontAttributeName, nil]

+(UIColor*)colorForHexColor:(NSString*)hexColor
{
    // If hexColor is less than 6 long, we don't know what color it is.
    if([hexColor length] < 6)
    {
        return [UIColor blackColor];
    }
    
    // If hexColor is 7 long (contains the #), trim the first character
    if([hexColor length] == 7)
    {
        hexColor = [hexColor substringFromIndex:1];
    }
    
    // Now that hexColor is 6 long, split it into its composite color components
    long int red = strtol([[hexColor substringWithRange:NSMakeRange(0, 2)] cStringUsingEncoding:NSUTF8StringEncoding],
                           NULL,
                          16);
    long int green = strtol([[hexColor substringWithRange:NSMakeRange(2, 2)] cStringUsingEncoding:NSUTF8StringEncoding],
                            NULL,
                            16);
    long int blue = strtol([[hexColor substringWithRange:NSMakeRange(4, 2)] cStringUsingEncoding:NSUTF8StringEncoding],
                           NULL,
                           16);
    
    
    UIColor* color = [UIColor colorWithRed:red / 255.0
                                     green:green / 255.0
                                      blue:blue / 255.0
                                     alpha:1.0];
    
    return color;
}

+(id)attributeForFontStyle:(NSString*)fontStyle
{
    if([fontStyle isEqualToString:@"bold"])
    {
        // Bold the font
        return (__bridge id)CTFontCreateCopyWithSymbolicTraits([GNTextGeometry coreTextFont],
                                                               0.0,
                                                               NULL,
                                                               kCTFontBoldTrait,
                                                               kCTFontBoldTrait);
    }
    else if([fontStyle isEqualToString:@"italic"])
    {
        // Italicize the font
        return (__bridge id)CTFontCreateCopyWithSymbolicTraits([GNTextGeometry coreTextFont],
                                                               0.0,
                                                               NULL,
                                                               kCTFontItalicTrait,
                                                               kCTFontItalicTrait);
    }
    else
    {
        // Just return the font
        return (__bridge id)[GNTextGeometry coreTextFont];
    }
}

+(NSString*)transformedKeyForKey:(NSString*)tmKey
{
    // Big if-chain statement to return various NSAttributedString keys
    // for their corresponding TM plist keys
    
    // TODO: fontStyle, which is more complex
    
    if([tmKey isEqualToString:@"foreground"])
    {
        return (NSString*)kCTForegroundColorAttributeName;
    }
    else if([tmKey isEqualToString:@"fontStyle"])
    {
        return (NSString*)kCTFontAttributeName;
    }
    
    // If we didn't find it, return nil
    return nil;
}

+(NSDictionary*)attributesDictionaryForTMBundleAttributesDictionary:(NSDictionary*)tmDictionary
{
    NSMutableDictionary* attributesDictionary = [[NSMutableDictionary alloc] init];
    
    for(NSString* key in [tmDictionary allKeys])
    {
        NSString* transformedKey = [GNTMBundleAttributeNameTransformer transformedKeyForKey:key];
        if(transformedKey)
        {
            NSObject* value = [[NSObject alloc] init];
            
            // Now that we have the transformed key, transform the value if its
            // a color attribute
            if([colorAttributes containsObject:transformedKey])
            {
                UIColor* color = [GNTMBundleAttributeNameTransformer colorForHexColor:[tmDictionary valueForKey:key]];
                value = (id)[color CGColor];
            }
            // If it is a font attribute, then transform the value
            else if([fontAttributes containsObject:transformedKey])
            {
                value = (id)[GNTMBundleAttributeNameTransformer attributeForFontStyle:[tmDictionary valueForKey:key]];
            }
            else
            {
                value = [tmDictionary valueForKey:key];
            }
            
            [attributesDictionary setValue:value
                                    forKey:transformedKey];
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:attributesDictionary];
}


@end
