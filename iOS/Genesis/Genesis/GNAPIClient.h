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

#import <Foundation/Foundation.h>
#import "GNMediatorClient.h"

typedef void(^GNClientCallback)(BOOL succeeded, NSDictionary *info);

@interface GNAPIClient : NSObject
{
    GNMediatorClient *client;
}

@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) NSString *machineType;
@property (nonatomic, strong) NSString *machineName;

- (id)init;
- (id)initWithHost:(NSString*)Host andPort:(uint16_t)port;
- (id)initWithMediatorClient:(GNMediatorClient*)client;

/******************************* Mediator Interaction *******************************/

// Connect to the provide host and port. Enable SSL if the server supports it (not yet)
// callback is invoked when connection has been made or there was an error.
//
// After logging in, you should either use -[loginWithUsername:andPassword:withCallback:]
// or -[registerWithUsername:andPassword:withCallback:].
- (void)connectWithSSL:(BOOL)useSSL withCallback:(MediatorClientCallback)callback;
// Disconnects from the mediator.
- (void)disconnect;

// Logs into the mediator with the given username and password. Callback is invoked
// when successfully logged in or not.
//
// You should set the machineName property to something useful before calling this,
// since each machine name should be unique per user.
- (void)loginWithUsername:(NSString *)theUsername
              andPassword:(NSString *)thePassword
             withCallback:(GNClientCallback)callback;

// Registers the given account with the mediator. Callback is invoked when successfully
// registered or not.
- (void)registerWithUsername:(NSString *)theUsername
                 andPassword:(NSString *)thePassword
                withCallback:(GNClientCallback)callback;

// Gets all machines connected to the mediator under this account. Callback is invoked
// when clients are fetched or failure occurs.
- (void)getClientsWithCallback:(GNClientCallback)callback;

// An abstraction above -[getClientsWithCallback:], but filters the client list to all
// builders. Failures are simply passed through to callback.
- (void)getBuildersWithCallback:(GNClientCallback)callback;

/******************************* Builder Interactions *******************************/
/****** Interactions with builders. All these commands go through the mediator ******/

// Gets all projects from the given builder. The callback is invoked with all the
// projects names or on failure.
- (void)getProjectsFromBuilder:(NSString *)builder
                  withCallback:(GNClientCallback)callback;

// Gets all files from the builder. The callback is invoked either with all the files
// for the given project or when an error occurs.
- (void)getFilesFromBuilder:(NSString *)builder
                 forProject:(NSString *)project
               withCallback:(GNClientCallback)callback;

// Downloads the given file from the server.
- (void)downloadFile:(NSString *)filepath
         fromBuilder:(NSString *)builder
          andProject:(NSString *)project
        withCallback:(GNClientCallback)callback;

- (void)uploadFile:(NSString *)filepath
         toBuilder:(NSString *)builder
        andProject:(NSString *)project
      withContents:(NSString *)contents
      withCallback:(GNClientCallback)callback;

- (void)performAction:(NSString *)action
            toBuilder:(NSString *)builder
           andProject:(NSString *)project
   withStreamCallback:(GNClientCallback)streamCallback;

- (void)cancelActionForProject:(NSString *)project
                   fromBuilder:(NSString *)builder
                  withCallback:(GNClientCallback)callback;

- (void)inputString:(NSString *)string
          toBuilder:(NSString *)builder
         andProject:(NSString *)project
       withCallback:(GNClientCallback)callback;

@end
