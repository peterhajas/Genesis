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

#import "GNTextAttributer.h"
#import "GNFileManager.h"

@implementation GNTextAttributer

+(NSAttributedString*)attributedStringForText:(NSString*)text withExtension:(NSString*)extension
{
    NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    
    NSDictionary* languageDictionary = [GNTextAttributer languageDictionaryForExtension:extension];
    
    // Load the language patterns into an array
    
    NSArray* languagePatterns = [languageDictionary valueForKey:@"patterns"];
    for(NSDictionary* pattern in languagePatterns)
    {
        // For each pattern, check if it has a match and a name
        
        // If it does not, skip it
        if(![[pattern allKeys] containsObject:@"match"] ||
           ![[pattern allKeys] containsObject:@"name"])
        {
            continue;
        }
        
        // Now that we know it has a match and a name, load both
        NSRegularExpression* match = [NSRegularExpression regularExpressionWithPattern:[pattern valueForKey:@"match"]
                                                                               options:0
                                                                                 error:nil];
        NSString* name = [pattern valueForKey:@"name"];
        
        // Find all the matches in text that match this regular expression
        
        NSArray* matches = [match matchesInString:text
                                          options:0
                                            range:[text rangeOfString:text]];
        
        for(NSTextCheckingResult* regExMatch in matches)
        {
            NSRange matchRange = [regExMatch range];
            [attributedText setAttributes:[NSDictionary dictionaryWithObject:name
                                                                      forKey:GNTextGrammarTypeKey]
                                    range:matchRange];
        }
    }
    
    return [[NSAttributedString alloc] initWithAttributedString:attributedText];
}

+(NSDictionary*)languageDictionaryForExtension:(NSString*)extension
{
    NSString* languagesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"languages"];
    NSArray* languages = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:languagesPath
                                                                             error:nil];
    for(NSString* language in languages)
    {
        // Load languages/language into a dictionary
        NSString* languagePath = [languagesPath stringByAppendingPathComponent:language];
        
        NSDictionary* languageDictionary = [NSDictionary dictionaryWithContentsOfFile:languagePath];
        
        // If languageDictionary doesn't have a fileTypes key, skip it
        if(![[languageDictionary allKeys] containsObject:@"fileTypes"])
        {
            continue;
        }
        
        // If fileTypes is a string, check equality with that string
        if([[languageDictionary valueForKey:@"fileTypes"] isKindOfClass:[NSString class]])
        {
            if([[languageDictionary valueForKey:@"fileTypes"] isEqualToString:extension])
            {
                return languageDictionary;
            }
        }
        // Otherwise, if it's an array, check each element in that array
        else if([[languageDictionary valueForKey:@"fileTypes"] isKindOfClass:[NSArray class]])
        {
            if([[languageDictionary valueForKey:@"fileTypes"] containsObject:extension])
            {
                return languageDictionary;
            }
        }
    }
    
    // If we haven't found the extension yet, fall back to plaintext
    NSString* plainTextPath = [languagesPath stringByAppendingPathComponent:@"Plain text.plist"];
    return [NSDictionary dictionaryWithContentsOfFile:plainTextPath];
}

@end
