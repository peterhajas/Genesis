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

#import "GNTheme.h"
#import "GNTMBundleAttributeNameTransformer.h"
#import "GNTextAttributer.h"

@implementation GNTheme

-(id)initWthThemeName:(NSString*)name
{
    self = [super init];
    if(self)
    {
        // Load the theme dictionary from disk
        NSString* themesDirectoryPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"themes"];
        NSString* themePath = [themesDirectoryPath stringByAppendingPathComponent:name];
        themePath = [themePath stringByAppendingString:@".tmTheme"];
        
        NSDictionary* aggregateThemeDictionary = [NSDictionary dictionaryWithContentsOfFile:themePath];
        
        // Build our internal theme dictionary
        
        themeDictionary = [[NSMutableDictionary alloc] init];
        
        NSArray* themeSettingsArray = [aggregateThemeDictionary valueForKey:@"settings"];
        
        for(NSDictionary* themeSetting in themeSettingsArray)
        {
            // If this themeSetting doesn't have a "settings" or "scope" key, skip it
            if(![[themeSetting allKeys] containsObject:@"settings"] ||
               ![[themeSetting allKeys] containsObject:@"scope"])
            {
                continue;
            }
            
            // TODO: theme base settings only have a "settings" key, we should implement this
            
            // Now that we know we have a "settings" and "scope" key, grab the value
            // for each of these
            
            NSDictionary* settings = [themeSetting valueForKey:@"settings"];
            NSArray* scopeElements = [[themeSetting valueForKey:@"scope"] componentsSeparatedByString:@", "];
            
            // Transform settings into its NSAttributedString attribute equivalent
            NSDictionary* attributes = [GNTMBundleAttributeNameTransformer attributesDictionaryForTMBundleAttributesDictionary:settings];
            
            for(NSString* scopeElement in scopeElements)
            {
                // Set attributes as the value and scopeElement as the key
                [themeDictionary setValue:attributes
                                   forKey:scopeElement];
            }
        }
    }
    return self;
}

-(NSAttributedString*)coloredStringForAttributedString:(NSAttributedString*)attributedString
{
    NSMutableAttributedString* coloredString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    
    for(NSUInteger i = 0; i < [attributedString length]; i++)
    {
        NSRange attributeRange;
        
        id attributeAtIndex = [attributedString attribute:GNTextGrammarTypeKey
                                                  atIndex:i
                                           effectiveRange:&attributeRange];
        
        if(attributeAtIndex)
        {
            NSDictionary* attributeForScopeElement = [self attributesForScopeElement:attributeAtIndex];
            
            if(attributeForScopeElement != nil)
            {
                [coloredString setAttributes:attributeForScopeElement
                                       range:attributeRange];
            }
        }
    }
    
    return [[NSAttributedString alloc] initWithAttributedString:coloredString];
}

-(NSDictionary*)attributesForScopeElement:(NSString*)scopeElement
{
    /*
     Scope elements are formatted like this:

     constant.numeric.integer.hexadecimal.python
     
     but themes traditionally detect scope elements like this:
     
     constant.numeric
     
     So, we check our internal themeDictionary to see if has scopeElement.
     
     If not, trim off the last section (delimited by periods) and try again
     */
        
    while(![scopeElement isEqualToString:@""])
    {
        if([[themeDictionary allKeys] containsObject:scopeElement])
        {
            return [themeDictionary valueForKey:scopeElement];
        }
        scopeElement = [self trimmedScopeElement:scopeElement];
    }
    return nil;
}

-(NSString*)trimmedScopeElement:(NSString*)scopeElement
{
    // Split the scopeElement into its elements, by splitting by "."
    NSArray* scopeElementElements = [scopeElement componentsSeparatedByString:@"."];
    
    // For all but the last entry, stitch the scope elements back together
    NSString* trimmedScopeElement = @"";
    for(NSString* scopeElementElement in scopeElementElements)
    {
        if([scopeElementElement isEqual:[scopeElementElements lastObject]])
        {
            break;
        }
        trimmedScopeElement = [trimmedScopeElement stringByAppendingString:scopeElementElement];
        trimmedScopeElement = [trimmedScopeElement stringByAppendingString:@"."];
    }
    
    // Remove the trailing period
    if([trimmedScopeElement length] > 0)
    {
        trimmedScopeElement = [trimmedScopeElement substringToIndex:[trimmedScopeElement length] - 1];
    }
    
    return trimmedScopeElement;
}

@end
