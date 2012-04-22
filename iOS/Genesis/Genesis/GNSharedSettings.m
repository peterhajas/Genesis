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

#import "GNSharedSettings.h"

@implementation GNSharedSettings

+(GNSharedSettings*)sharedSettings
{
    static GNSharedSettings* sharedSettings;
    
    @synchronized(self)
    {
        if(!sharedSettings)
        {
            sharedSettings = [[GNSharedSettings alloc] init];
        }
        
        return sharedSettings;
    }
}

-(id)init
{
    self = [super init];
    if(self)
    {
        [self loadSettings];
    }
    return self;
}

-(void)loadSettings
{
    // Load settings from disk
    settings = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:GNSharedSettingsPlistPath
                                                                                                 ofType:@"plist"]];
    // If settings don't exist
    if(!settings)
    {
        // Create a dictionary in memory, load default settings
        settings = [[NSMutableDictionary alloc] init];
        [self resetToDefaults];
    }
}

-(id)valueForKey:(NSString*)key
{
    if([[settings allKeys] containsObject:key])
    {
        return [settings valueForKey:key];
    }
    else
    {
        NSLog(@"No setting for key %@", key);
        return nil;
    }
}

-(void)setValue:(id)value forKey:(NSString*)key
{
    [settings setValue:value forKey:key];
}

-(void)resetToDefaults
{
    settings = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:GNSharedSettingsDefaultsPlistPath
                                                                                                 ofType:@"plist"]];
    [self settingsChanged];
}

-(void)settingsChanged
{
    // Save settings to disk
    [settings writeToFile:[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:GNSharedSettingsPlistPath] stringByAppendingString:@".plist"]
               atomically:YES];
}

@end
