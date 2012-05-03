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

#import "GNNetworkSync.h"
#import "GNFileManager.h"
#import "GNAppDelegate.h"
#import "GNNotificationNames.h"

@implementation GNNetworkSync

@synthesize networkManager;

- (id)initWithNetworkManager:(GNNetworkManager *)theNetworkManager;
{
    if (self = [super init])
    {
        self.networkManager = theNetworkManager;
        fileDownloadQueue = [NSMutableArray new];
    }
    return self;
}


#pragma mark - Network Manager Delegate
// TODO: handle error states....

- (void)didConnectToMediatorWithError:(NSError *)error
{
    if (error)
    {
        NSLog(@"Failed to connect to mediator: %@", error);
    }
    else
    {
        NSLog(@"Connected.");
    }
}

- (void)didAuthenticateWithError:(NSError *)error
{
    if (error)
    {
        NSLog(@"Failed to authenticate: %@", error);
    }
}

- (void)didRegisterWithError:(NSError *)error
{
    if (error)
    {
        NSLog(@"Failed to register: %@", error);
    }
}

- (void)didReceiveProjects:(NSArray *)projects error:(NSError *)error
{
    if (!error)
    {
        // list projects? select projects?
        NSLog(@"Projects: %@", projects);
        for(NSString* projectName in projects)
        {
            if([GNFileManager entryExistsAtRelativePath:projectName isDirectory:YES])
            {
                return;
            }
            
            // Create the new project
            GNAppDelegate* appDelegate = (GNAppDelegate*)[[UIApplication sharedApplication] delegate];
            NSManagedObjectContext* managedObjectContext = [appDelegate managedObjectContext];
            
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GNProject" 
                                                                 inManagedObjectContext:managedObjectContext];
            
            GNProject* project = [[GNProject alloc] initWithEntity:entityDescription
                                    insertIntoManagedObjectContext:managedObjectContext];
            
            [managedObjectContext insertObject:project];
            
            // Set the project name
            [project setValue:projectName forKey:@"name"];
            
            // Save the context
            [appDelegate saveContext];
            
            // Create a new directory for this project
            [GNFileManager createFilesystemEntryAtRelativePath:@""
                                                      withName:projectName
                                                   isDirectory:YES];
            //[[projectBrowser tableView] reloadData];
            [[NSNotificationCenter defaultCenter] postNotificationName:GNProjectsUpdatedNotification
                                                                object:self];
        }
    }
    else
    {
        NSLog(@"Failed to get projects: %@", error);
    }
}

- (void)didReceiveFiles:(NSArray *)files forBranch:(NSString *)branch forProject:(NSString *)projectName error:(NSError *)error
{
    if (!error)
    {
        // list files
        NSLog(@"Files: %@", files);
        
        fileDownloadQueue = [NSMutableArray arrayWithObject:projectName];
        for (NSDictionary *file in files)
        {
            NSString *filepath = [file objectForKey:@"path"];
            NSString *folder = [projectName stringByAppendingPathComponent:[filepath stringByDeletingLastPathComponent]];
            NSString *filename = [[filepath pathComponents] lastObject];
            if(![GNFileManager entryExistsAtRelativePath:filepath isDirectory:NO])
            {
                NSLog(@"Create: %@ -> %@", folder, filename);
                // Ok, excellent! The entity doesn't already exist. Let's create it!
                [GNFileManager createFilesystemEntryAtRelativePath:folder
                                                          withName:filename
                                                       isDirectory:NO];
                // TODO: should we be handling error for creation attempt?
             }
            //[self.networkManager downloadFile:filepath forProject:projectName];
            // we only support text right now
            NSLog(@"File: %@", file);
            NSString *mimetype = [file objectForKey:@"mimetype"];
            NSLog(@"mimetype: %@", mimetype);
            if ([mimetype isEqualToString:@""])
                continue;
            NSRange range = [mimetype rangeOfString:@"text/"];
            if (range.location == 0)
            {
                [fileDownloadQueue addObject:file];
            }
        }
        NSLog(@"Files Queue: %@", fileDownloadQueue);
        if ([fileDownloadQueue count] > 1)
        {
            [self.networkManager downloadFile:[[fileDownloadQueue lastObject] objectForKey:@"path"]
                                   forProject:projectName];
            [fileDownloadQueue removeLastObject];
        }
        
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:files, @"files",
                              branch, @"branch",
                              projectName, @"project",
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:GNFilesForProjectNotification
                                                            object:self
                                                          userInfo:info];
    }
    else
    {
        NSLog(@"Failed to get files: %@", error);
    }
}

- (void)didUploadFile:(NSString *)filepath forProject:(NSString *)project error:(NSError *)error
{
    if (!error)
    {
        // handle file upload ?
        NSLog(@"Uploaded file: %@", filepath);
    }
    else
    {
        NSLog(@"Failed to upload file: %@", error);
    }
}

- (void)didDownloadFile:(NSString *)filepath
           withContents:(NSString *)contents
             forProject:(NSString *)projectName
                  error:(NSError *)error
{
    if (!error)
    {
        // handle downloaded file
        NSLog(@"Downloaded file: %@", filepath);
        // TODO: write file contents here
        NSString *fullPath = [projectName stringByAppendingPathComponent:filepath];
        [GNFileManager setFileContentsAtRelativePath:fullPath toContent:[contents dataUsingEncoding:NSUTF8StringEncoding]];
        
        if ([fileDownloadQueue count] > 1)
        {
            [self.networkManager downloadFile:[[fileDownloadQueue lastObject] objectForKey:@"path"]
                                   forProject:projectName];
            [fileDownloadQueue removeLastObject];
        }
        
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:filepath, @"filepath",
                              projectName, @"project",
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:GNDownloadedFileNotification
                                                            object:self
                                                          userInfo:info];
        [[NSNotificationCenter defaultCenter] postNotificationName:GNRefreshFileContentsNotification
                                                            object:self
                                                          userInfo:info];
    }
    else
    {
        NSLog(@"Failed to download file: %@", error);
    }
}

@end
