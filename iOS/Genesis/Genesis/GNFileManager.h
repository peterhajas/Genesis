//
//  GNFileManager.h
//  Genesis
//
//  Created by Peter Hajas on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GNFileManager : NSObject

+(NSString*)absolutePathForRelativePath:(NSString*)relativePath;

+(NSData*)fileContentsAtRelativePath:(NSString*)relativePath;
+(void)setFileContentsAtRelativePath:(NSString*)relativePath toContent:(NSData*)content;

+(NSArray*)directoryContentsAtRelativePath:(NSString*)relativePath;
+(NSArray*)directoryFileContentsAtRelativePath:(NSString*)relativePath;
+(NSArray*)directoryDirectoryContentsAtRelativePath:(NSString*)relativePath;
+(BOOL)entryExistsAtRelativePath:(NSString*)relativePath isDirectory:(BOOL)isDirectory;

+(BOOL)createFilesystemEntryAtRelativePath:(NSString*)relativePath withName:(NSString*)name isDirectory:(BOOL)isDirectory;
+(void)removeContentAtRelativePath:(NSString*)relativePath;

@end
