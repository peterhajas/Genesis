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
    id sender;
}

@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) NSString *machineType;
@property (nonatomic, strong) NSString *machineName;

- (id)initWithHost:(NSString*)Host andPort:(uint16_t)port;
- (id)initWithMediatorClient:(GNMediatorClient*)client;

/******************************* Mediator Interaction *******************************/

// Connect to the provide host and port. Enable SSL if the server supports it (not yet)
// callback is invoked when connection has been made or there was an error.
//
// After logging in, you should either use -[loginWithPassword:forUsername:withCallback:]
// or -[registerWithUsername:andPassword:withCallback:].
- (void)connectWithSSL:(BOOL)useSSL withCallback:(MediatorClientCallback)callback;
// Disconnects from the mediator.
- (void)disconnect;

// Logs into the mediator with the given username and password. Callback is invoked
// when successfully logged in or not.
//
// You should set the machineName property to something useful before calling this,
// since each machine name should be unique per user.
// 
// Returns the hashed password, which can be stored
- (NSString *)loginWithPassword:(NSString *)thePassword
                    forUsername:(NSString *)theUsername
                   withCallback:(GNClientCallback)callback;


// Logs into the mediator with the given username and password hash. Callback is invoked
// when successfully logged in or not.
//
// You should set the machineName property to something useful before calling this,
// since each machine name should be unique per user.
// 
// Returns the hashed password - just to be consistent.
- (NSString *)loginWithPasswordHash:(NSString *)thePasswordHash
                        forUsername:(NSString *)theUsername
                       withCallback:(GNClientCallback)callback;

// Registers the given account with the mediator. Callback is invoked when successfully
// registered or not.
- (void)registerWithUsername:(NSString *)theUsername
                 andPassword:(NSString *)thePassword
                withCallback:(GNClientCallback)callback;

// Gets all machines connected to the mediator under this account. Callback is invoked
// when clients are fetched or failure occurs.
//
// info => {"clients": {"<machine name>": "builder.genesis.osx"}}
- (void)getClientsWithCallback:(GNClientCallback)callback;

// An abstraction above -[getClientsWithCallback:], but filters the client list to all
// builders. Failures are simply passed through to callback.
//
// info => {"clients": {"myMachine": "builder.genesis.osx",
//                      "anotherMachine": "editor.genesis.ios.iPhone"},
//          "builders": {"myMachine": "builder.genesis.osx"}}
- (void)getBuildersWithCallback:(GNClientCallback)callback;

/******************************* Builder Interactions *******************************/
/****** Interactions with builders. All these commands go through the mediator ******/

// Gets all projects from the given builder. The callback is invoked with all the
// projects names or on failure.
//
// info => {"projects": ["myProject1", "myProject2"]}
- (void)getProjectsFromBuilder:(NSString *)builder
                  withCallback:(GNClientCallback)callback;

// Gets all files from the builder. The callback is invoked either with all the files
// for the given project or when an error occurs.
//
// info is set identically to -[getFilesFromBuilder:forProject:onBranch:withCallback:]
- (void)getFilesFromBuilder:(NSString *)builder
                 forProject:(NSString *)project
               withCallback:(GNClientCallback)callback;

// Gets all files from the builder. The callback is invoked either with all the files
// for the given project or when an error occurs. If branch is an empty string or nil,
// the current branch is used.
//
// As of now, there should be no pending changes to commit changing branches or else the
// version control may reject it.
//
// info => {"files": [
//              {"name": "foo.py",
//               "path": "rel/path/to/foo.py",
//               "size": 20,
//               "kind": "<TBA/not implemented yet>",
//               "mimetype": "text/x-python"},
//              {"name": "foo2.py",
//               "path": "rel/path/to/foo2.py",
//               "size": 54,
//               "kind": "<TBA/not implemented yet>",
//               "mimetype": "text/x-python"},
//          ],
//         "branch": "currentBranch"}
- (void)getFilesFromBuilder:(NSString *)builder
                 forProject:(NSString *)project
                   onBranch:(NSString *)branch
               withCallback:(GNClientCallback)callback;

// Gets all the branches from the builder. The callback is invoked either with all the branches
// for the given project or when an error occurs.
//
// info => {"branches": [
//              {"name": "master"},
//              {"name": "demo1"}
//          ],
//         "head": "master"}
- (void)getBranchesFromBuilder:(NSString*)builder
                    forProject:(NSString *)project
                  withCallback:(GNClientCallback)callback;

// Downloads the given file from the project.
//
// info => {"project": "myProject",
//          "filepath": "rel/path/to/file.py",
//          "contents": "print 'hello world'"}
- (void)downloadFile:(NSString *)filepath
         fromBuilder:(NSString *)builder
          andProject:(NSString *)project
        withCallback:(GNClientCallback)callback;

// Uploads the given file contents as the filepath to the builder.
//
// info => {}
- (void)uploadFile:(NSString *)filepath
         toBuilder:(NSString *)builder
        andProject:(NSString *)project
      withContents:(NSString *)contents
      withCallback:(GNClientCallback)callback;

// Performs a builder action. The builder will stream stdout to us.
// streamCallback is invoked multiple times: one for streaming data; another for
// end of stream, and another for return code. Multiple stream notifications can
// be received until stream_eof and return_code.
// 
// info => {"name": "stream", "project": "myProject", "contents": "hello world\n"}
//      => {"name": "stream_eof", "project": "myProject"}
//      => {"name": "return_code", "project": "myProject", "return_code": 0}
- (void)performAction:(NSString *)action
            toBuilder:(NSString *)builder
           andProject:(NSString *)project
   withStreamCallback:(GNClientCallback)streamCallback;

// Terminates the operation being done by -[performAction:toBuilder:andProject:withStreamCallback]
- (void)cancelActionForProject:(NSString *)project
                   fromBuilder:(NSString *)builder
                  withCallback:(GNClientCallback)callback;

// Sends input to a -[performAction:toBuilder:andProject:withStreamCallback] operation
// as standard input. Used to fill out input for a program.
//
// Since this the raw string. Remember to give newlines.
//
// info => {}
- (void)inputString:(NSString *)string
          toBuilder:(NSString *)builder
         andProject:(NSString *)project
       withCallback:(GNClientCallback)callback;

@end
