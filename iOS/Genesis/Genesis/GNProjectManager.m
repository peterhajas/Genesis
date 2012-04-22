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

#import "GNProjectManager.h"
#import "GNProject.h"
#import "GNAppDelegate.h"
#import "GNAPIClient.h"
#import "GNFileManager.h"
#import "GNNetworkFileManager.h"

@implementation GNProjectManager

-(void)refresh
{
    [GNSharedAppDelegateAPIClient getProjectsFromBuilder:[[GNSharedAppDelegateNetworkManager builders] objectAtIndex:0]
                                            withCallback:^(BOOL succeeded, NSDictionary* info)
     {
         if(succeeded)
         {
             NSArray* projectNames = [info valueForKey:@"projects"];
             for(NSString* projectName in projectNames)
             {
                 [self refreshProjectWithName:projectName];
             }
         }
         else
         {
             // Something went wrong! TODO: handle this in a user-presentable way
             NSLog(@"couldn't grab project names");
         }
     }];
}

-(void)refreshProjectWithName:(NSString*)projectName
{
    // First, we need to check if this project exists locally
    if(![[self allProjectNames] containsObject:projectName])
    {
        // The project does not exist locally. Create it.
        [self createProjectWithName:projectName];
    }
    
    // Now that we know the project exists locally, refresh it
    [GNNetworkFileManager pullAllFilesInRelativePath:projectName];
}

-(void)createProjectWithName:(NSString*)name
{
    NSManagedObjectContext* managedObjectContext = [GNSharedAppDelegate managedObjectContext];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GNProject" 
                                                         inManagedObjectContext:managedObjectContext];
    
    GNProject* project = [[GNProject alloc] initWithEntity:entityDescription
                            insertIntoManagedObjectContext:managedObjectContext];
    
    [managedObjectContext insertObject:project];
    
    // Set the project name
    [project setValue:name forKey:@"name"];
    
    // Save the context
    [GNSharedAppDelegate saveContext];
    
    // Create a new directory for this project
    [GNFileManager createFilesystemEntryAtRelativePath:@""
                                              withName:name
                                           isDirectory:YES];
}

-(NSArray*)allProjectNames
{
    NSManagedObjectContext* managedObjectContext = [(GNAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectModel* managedObjectModel = [(GNAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectModel];
    
    NSFetchRequest* allProjectsFetchRequest = [managedObjectModel fetchRequestTemplateForName:@"GNAllProjectsFetchRequest"];
    
    NSArray* fetchResults = [managedObjectContext executeFetchRequest:allProjectsFetchRequest error:nil];
    
    return fetchResults;
}

@end
