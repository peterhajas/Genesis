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

#import "GNNetworkManager.h"

@implementation GNNetworkManager

-(id)init
{
    self = [super init];
    if(self)
    {
        apiClient = [[GNAPIClient alloc] initWithHost:@"localhost" andPort:8080];
        [apiClient connectWithSSL:NO withCallback:^(NSError* error)
         {
             [apiClient loginWithPassword:@"password"
                              forUsername:@"jeff" 
                             withCallback:^(BOOL succeeded, NSDictionary* loginInformation)
              {
                  if(succeeded)
                  {
                      [self grabBuilderNames];
                  }
              }];
         }];
        builderNames = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)syncFile:(NSString*)filePath inProject:(NSString*)projectName forBuilder:(NSString*)builderName
{
    
}

-(void)syncProject:(NSString*)projectName inBuilder:(NSString*)builderName
{
    // Grab all the filenames
    [apiClient getFilesFromBuilder:builderName
                        forProject:projectName
                      withCallback:^(BOOL succeeded, NSDictionary* info)
     {
         if(succeeded)
         {
             NSArray* files = [info valueForKey:@"files"];
             for(NSDictionary* file in files)
             {
                 NSString* filePath = [file valueForKey:@"path"];
                 [self syncFile:filePath
                      inProject:projectName
                     forBuilder:builderName];
             }
         }
     }];
}

-(void)syncAllProjects
{
    for(NSString* builder in builderNames)
    {
        // Grab the projects for each builder
        [apiClient getProjectsFromBuilder:builder
                             withCallback:^(BOOL succeeded, NSDictionary* info)
         {
             if(succeeded)
             {
                 NSArray* projects = [info valueForKey:@"projects"];
                 for(NSString* project in projects)
                 {
                     // Sync the project
                     [self syncProject:project inBuilder:builder];
                 }
             }
         }];
    }
}

-(void)grabBuilderNames
{
    [apiClient getBuildersWithCallback:^(BOOL succeeded, NSDictionary* builders)
     {
         if(succeeded)
         {
             // Try to grab builders out of the builders dictionary
             NSDictionary* buildersDictionary = [builders objectForKey:@"builders"];
             NSArray* buildersArray = [buildersDictionary allKeys];
             
             [builderNames removeAllObjects];
             
             // Record all the builders we find
             builderNames = [NSMutableArray arrayWithArray:buildersArray];
         }
     }];
}

@end
