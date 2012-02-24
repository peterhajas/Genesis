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


#import "GNAppDelegate.h"
#import "GNProjectBrowserViewController.h"

#import "GNNetworkRequest.h"
#import "NSString+GNNSStringHashes.h"

@implementation GNAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // Create a project browser table view
    GNProjectBrowserViewController* projectBrowser = [[GNProjectBrowserViewController alloc] initWithNibName:@"GNProjectBrowserViewController" 
                                                                                                      bundle:[NSBundle mainBundle]];
    
    // Create the navigation controller
    navigationController = [[UINavigationController alloc] initWithRootViewController:projectBrowser];
    
    // Set global appearance settings
    [[UINavigationBar appearance] setTintColor:kGNTintColor];
    
    [self.window setRootViewController:navigationController];
    
    // Test Code
    client = [[GNAPIClient alloc] initWithHost:@"genesis.coralset.com" andPort:7331];
    [client connectWithSSL:NO withCallback:^(NSError *error) {
        NSLog(@"Connection: %@", error);
        [client loginWithPassword:@"password" forUsername:@"jeff" withCallback:^(BOOL succeeded, NSDictionary *info) {
            if (succeeded)
            {
                NSLog(@"Successfully logged in");
                [client getBuildersWithCallback:^(BOOL succeeded, NSDictionary *info) {
                    if (succeeded)
                    {
                        NSLog(@"getClients => %@", info);

                        [client getBuildersWithCallback:^(BOOL didSucceed, NSDictionary *builderDict) {
                            // Look for a builder.genesis.OSX type
                            NSString* builderName = @"";
                            for(NSString* key in [[builderDict valueForKey:@"clients"] allKeys])
                            {
                                if([[[builderDict valueForKey:@"clients"] valueForKey:key] isEqualToString:@"builder.genesis.OSX"])
                                {
                                    builderName = key;
                                    break;
                                }
                            }
                            if(![builderName isEqualToString:@""])
                            {
                                NSLog(@"builderName => %@", builderName);
                                // Ok! We have the builder name! Let's ask it for the projects
                                [client getProjectsFromBuilder:builderName
                                                  withCallback:^(BOOL projectGrabbingSucceeded, NSDictionary *projectDict)
                                 {
                                     NSLog(@"projectDict => %@", projectDict);
                                 }];
                            }
                        }];
                    }
                    else
                    {
                        NSLog(@"getClients => Failed.");
                    }
                }];
            }
            else
            {
                NSLog(@"Failed to log in :(");
            }
        }];
    }];
    // End Test Code
        
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[self managedObjectContext] save:nil]; //TODO: handle managed object context save errors
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Genesis" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Genesis.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
