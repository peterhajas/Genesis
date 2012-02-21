//
//  GNFileManager.m
//  Genesis
//
//  Created by Peter Hajas on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

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
                                  withIntermediateDirectories:NO
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
