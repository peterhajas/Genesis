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

+(BOOL)isValidPattern:(NSArray*)patternKeys
{
    if(([patternKeys containsObject:@"match"] &&
        [patternKeys containsObject:@"name"]) ||
       ([patternKeys containsObject:@"begin"] &&
        [patternKeys containsObject:@"end"]))
    {
        return YES;
    }
    return NO;
}

+(NSAttributedString*)attributedStringForText:(NSString*)text withLanguageDictionary:(NSDictionary*)languageDictionary
{
    NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:text];
        
    // Load the language patterns into an array
    
    if([text isEqualToString:@""])
    {
        return attributedText;
    }
    
    NSArray* languagePatterns = [languageDictionary valueForKey:@"patterns"];
    for(NSDictionary* pattern in languagePatterns)
    {
        // For each pattern, check its validity
        if(![GNTextAttributer isValidPattern:[pattern allKeys]])
        {
            continue;
        }
        
        // If it has a match and a name, we can do simple regexing
        if([[pattern allKeys] containsObject:@"match"])
        {
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
        else
        {
            // It's more complex. Find the beginning and ending expressions
            NSRegularExpression* begin = [NSRegularExpression regularExpressionWithPattern:[pattern valueForKey:@"begin"]
                                                                                   options:0
                                                                                     error:nil];
            NSRegularExpression* end = [NSRegularExpression regularExpressionWithPattern:[pattern valueForKey:@"end"]
                                                                                 options:0
                                                                                   error:nil];
            
            NSArray* beginCaptures = nil;
            NSArray* endCaptures = nil;
            NSArray* captures = nil;
            
            if([[pattern allKeys] containsObject:@"beginCaptures"])
            {
                beginCaptures = [GNTextAttributer grabCapturesNames:[pattern valueForKey:@"beginCaptures"]];
            }
            if([[pattern allKeys] containsObject:@"endCaptures"])
            {
                endCaptures = [GNTextAttributer grabCapturesNames:[pattern valueForKey:@"endCaptures"]];
            }
            if([[pattern allKeys] containsObject:@"captures"])
            {
                captures = [GNTextAttributer grabCapturesNames:[pattern valueForKey:@"captures"]];
            }
            
            // Find all the elements of text which match begin and end
            
            NSArray* beginMatches = [begin matchesInString:text
                                                   options:0
                                                     range:[text rangeOfString:text]];
            
            NSArray* endMatches = [end matchesInString:text
                                               options:0
                                                 range:[text rangeOfString:text]];
            
            for(NSTextCheckingResult* beginMatch in beginMatches)
            {                
                // Find the range of the beginMatch
                NSRange matchRange = [beginMatch range];
                
                if(beginCaptures)
                {
                    // For each element in beginCaptures, apply that to the range of beginMatch
                    for(NSString* beginCapture in beginCaptures)
                    {
                        [attributedText setAttributes:[NSDictionary dictionaryWithObject:beginCapture
                                                                                  forKey:GNTextGrammarTypeKey]
                                                range:matchRange];
                    }
                }
                
                if(captures)
                {
                    // We need to find, from beginMatch's end to the end of the string, the first
                    // occurence of an en end match.
                    NSArray* endMatchesForBeginMatch = [end matchesInString:text
                                                                    options:0
                                                                      range:NSMakeRange(matchRange.location + matchRange.length,
                                                                                        [text length])];
                    
                    
                    NSRange rangeOfMatch;
                    
                    // If there are no end matches for this begin match,
                    // the range of our match goes to the end of the string
                    if([endMatchesForBeginMatch count] == 0)
                    {
                        rangeOfMatch = NSMakeRange(matchRange.location,
                                                   [text length] - matchRange.location);
                        
                    }
                    else
                    {
                        // If it's not empty, then the first end match is the one we'll attribute to
                        NSTextCheckingResult* endMatchForBeginMatch = [endMatchesForBeginMatch objectAtIndex:0];
                        
                        // The endpoint of the attribution range is the end of endMatchForBeginMatch
                        NSRange endMatchForBeginMatchRange = [endMatchForBeginMatch range];
                        
                        // The length our match is the difference between the absolute location of
                        // endMatchForBeginMatchRange and the absolute location of matchRange.
                        
                        rangeOfMatch = NSMakeRange(matchRange.location,
                                                   (endMatchForBeginMatchRange.location+ endMatchForBeginMatchRange.length) - (matchRange.location + matchRange.length));
                    }
                    
                    for(NSString* capture in captures)
                    {
                        [attributedText setAttributes:[NSDictionary dictionaryWithObject:capture
                                                                                  forKey:GNTextGrammarTypeKey]
                                                range:rangeOfMatch];
                    }
                }
            }
            for(NSTextCheckingResult* endMatch in endMatches)
            {
                if(endCaptures)
                {
                    // Find the range of the endMatch
                    NSRange matchRange = [endMatch range];
                    
                    // For each element in endCaptures, apply that to the range of endMatch
                    for(NSString* endCapture in endCaptures)
                    {
                        [attributedText setAttributes:[NSDictionary dictionaryWithObject:endCapture
                                                                                  forKey:GNTextGrammarTypeKey]
                                                range:matchRange];
                    }
                }
            }
        }
    }
    
    return [[NSAttributedString alloc] initWithAttributedString:attributedText];
}

+(NSArray*)grabCapturesNames:(NSDictionary*)capturesDict
{
    NSMutableArray* capturesNames = [[NSMutableArray alloc] init];
    for(NSString* key in [capturesDict allKeys])
    {
        NSDictionary* captureEntry = [capturesDict valueForKey:key];
        NSString* captureName = [captureEntry valueForKey:@"name"];
        [capturesNames addObject:captureName];
    }
    return [NSArray arrayWithArray:capturesNames];
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
