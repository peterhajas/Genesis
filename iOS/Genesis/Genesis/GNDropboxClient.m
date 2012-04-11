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

#import "GNDropboxClient.h"

@implementation GNDropboxClient

-(id)init
{
    self = [super init];
    if(self)
    {
        // Initialize DropBox session
        DBSession* session = [[DBSession alloc] initWithAppKey:@"32ukeqeu6af0cft"
                                                     appSecret:@"secret!"
                                                          root:kDBRootDropbox];
        [DBSession setSharedSession:session];
        
        restClient = nil;
        
        if([session isLinked])
        {
            [self initializeRestClient];
        }
    }
    return self;
}

-(void)initializeRestClient
{
    if(!restClient)
    {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        [restClient setDelegate:self];
    }
}

#pragma mark Dropbox commands

-(void)link
{
    // If the DBSession isn't linked, link it
    if(![[DBSession sharedSession] isLinked])
    {
        [[DBSession sharedSession] link];
        [self initializeRestClient];
    }
}

-(void)listContentsAtDropboxPath:(NSString*)path
{
    [restClient loadMetadata:path];
}

-(void)downloadFileToLocalAbsolutePath:(NSString*)localPath fromDropboxPath:(NSString*)dropboxPath
{
    [restClient loadFile:dropboxPath
                intoPath:localPath];
}

-(void)uploadFileAtLocalAbsolutePath:(NSString*)localPath toDropboxPath:(NSString*)dropboxPath
{
    [restClient uploadFile:[localPath lastPathComponent]
                    toPath:dropboxPath
             withParentRev:nil
                  fromPath:localPath];
}

#pragma mark Dropbox success handlers

-(void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    if (metadata.isDirectory)
    {
        NSLog(@"Folder '%@' contains:", metadata.path);
        for (DBMetadata *file in metadata.contents)
        {
            NSLog(@"\t%@", file.filename);
        }
    }
    
    if([metadata isDirectory])
    {
        // Get all the files and directories at this path
        NSMutableArray* files = [[NSMutableArray alloc] init];
        NSMutableArray* directories = [[NSMutableArray alloc] init];
        
        for(DBMetadata* entry in [metadata contents])
        {
            NSString* path = [entry path];
            NSString* filename = [entry filename];
            
            if(![entry isDirectory])
            {
                [files addObject:path];
            }
            else
            {
                [directories addObject:path];
            }
        }
        
        // Create the dictionary
        NSDictionary* listingDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:files, directories, nil]
                                                                      forKeys:[NSArray arrayWithObjects:kGNDropboxClientFilesAtPath, kGNDropboxClientDirectoriesAtPath, nil]];
        
        [self announceDropboxNotification:kGNDropboxClientFileListingNotification
                               withObject:[metadata path]
                                  andInfo:listingDictionary];
    }
    
    
}

-(void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
{
    [self announceDropboxNotification:kGNDropboxClientFileDownloadCompleteNotification
                           withObject:localPath
                              andInfo:nil];
}

-(void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    
    [self announceDropboxNotification:kGNDropboxClientFileUploadCompleteNotification
                           withObject:srcPath
                              andInfo:nil];
}

#pragma mark Dropbox failure handlers

// TODO: These should pass to some sort of error handler

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    NSLog(@"There was an error loading the file - %@", error);
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSLog(@"File upload failed with error - %@", error);
}

#pragma mark NSNotifcationCenter convenience method
-(void)announceDropboxNotification:(NSString*)notification withObject:(NSObject*)object andInfo:(NSDictionary*)info
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification
                                                        object:object
                                                      userInfo:info];
}

@end
