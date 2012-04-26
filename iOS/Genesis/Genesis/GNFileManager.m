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

#import "GNFileManager.h"

@implementation GNFileManager

+(NSString*)absolutePathForRelativePath:(NSString*)relativePath
{
    // Grab the documents directory
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* absolutePath = [documentPath stringByAppendingPathComponent:relativePath];
    
    return absolutePath;
}

#pragma mark -
#pragma mark Enumerating contents

+(NSData*)fileContentsAtRelativePath:(NSString*)relativePath
{
    NSString* absolutePath = [GNFileManager absolutePathForRelativePath:relativePath];
    
    return [NSData dataWithContentsOfFile:absolutePath];
}

+(void)setFileContentsAtRelativePath:(NSString*)relativePath toContent:(NSData*)content
{
    NSString* absolutePath = [GNFileManager absolutePathForRelativePath:relativePath];
    
    [content writeToFile:absolutePath atomically:YES];
}

#pragma mark Directory contents

+(NSArray*)directoryContentsAtRelativePath:(NSString*)relativePath
{
    NSString* absolutePath = [GNFileManager absolutePathForRelativePath:relativePath];
    
    NSError* error = nil;
    
    NSArray* fileContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:absolutePath
                                                                                error:&error];
    
    if(error)
    {
        NSLog(@"Encountered an error grabbing directory contents at path %@ : %@", relativePath, [error localizedDescription]);
        return [NSArray arrayWithObject:nil];
    }
    
return fileContents;
}

+(NSArray*)directoryFileContentsAtRelativePath:(NSString*)relativePath
{
    NSString* absolutePath = [GNFileManager absolutePathForRelativePath:relativePath];
    NSArray* directoryContents = [GNFileManager directoryContentsAtRelativePath:relativePath];
    
    NSMutableArray* fileContents = [[NSMutableArray alloc] init];
    
    for(NSString* entry in directoryContents)
    {
        NSString* entryAbsolutePath = [absolutePath stringByAppendingPathComponent:entry];
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:entryAbsolutePath
                                             isDirectory:&isDirectory];
        if(!isDirectory)
        {
            [fileContents addObject:entry];
        }
    }
    
    return [NSArray arrayWithArray:fileContents];
}

+(NSArray*)directoryDirectoryContentsAtRelativePath:(NSString*)relativePath
{
    NSString* absolutePath = [GNFileManager absolutePathForRelativePath:relativePath];
    NSArray* directoryContents = [GNFileManager directoryContentsAtRelativePath:relativePath];
    
    NSMutableArray* fileContents = [[NSMutableArray alloc] init];
    
    for(NSString* entry in directoryContents)
    {
        NSString* entryAbsolutePath = [absolutePath stringByAppendingPathComponent:entry];
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:entryAbsolutePath
                                             isDirectory:&isDirectory];
        if(isDirectory)
        {
            [fileContents addObject:entry];
        }
    }
    
    return [NSArray arrayWithArray:fileContents];
}

+(BOOL)entryExistsAtRelativePath:(NSString*)relativePath isDirectory:(BOOL)isDirectory
{
    NSString* absolutePath = [GNFileManager absolutePathForRelativePath:relativePath];
    BOOL entryIsDirectory;
    
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&entryIsDirectory];
    
    return ((isDirectory == entryIsDirectory) && exists);
}

#pragma mark Creating/removing entries

+(BOOL)createFilesystemEntryAtRelativePath:(NSString*)relativePath withName:(NSString*)name isDirectory:(BOOL)isDirectory
{
    NSString* absolutePath = [[GNFileManager absolutePathForRelativePath:relativePath] stringByAppendingPathComponent:name];
    
    // Check if this entry exists. If it doesn't, we can't create it
    if([self entryExistsAtRelativePath:[relativePath stringByAppendingPathComponent:name] isDirectory:isDirectory])
    {
        return NO;
    }
    
    NSError* error = nil;
    
    if(isDirectory)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:absolutePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if(error)
        {
            NSLog(@"Encountered an error creating directory at path %@ : %@", relativePath, [error localizedDescription]);
            return NO;
        }
    }
    else 
    {
        [[NSFileManager defaultManager] createFileAtPath:absolutePath
                                                contents:nil
                                              attributes:nil];
    }
    
    return YES;
}

+(void)removeContentAtRelativePath:(NSString*)relativePath
{
    NSString* absolutePath = [GNFileManager absolutePathForRelativePath:relativePath];
    
    NSError* error = nil;
    
    [[NSFileManager defaultManager] removeItemAtPath:absolutePath 
                                               error:&error];
    
    if(error)
    {
        NSLog(@"Encountered an removing entry at path %@ : %@", relativePath, [error localizedDescription]);
    }
}

@end
