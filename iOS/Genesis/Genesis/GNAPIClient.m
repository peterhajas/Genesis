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


#import "GNAPIClient.h"
#import "NSString+GNNSStringHashes.h"
#import "GNNetworkRequest.h"
#import "GNNetworkResponse.h"
#import "GNNetworkConstants.h"

@implementation GNAPIClient

@synthesize machineName;

#pragma mark - Constructors

- (id)initWithMediatorClient:(GNMediatorClient *)theClient
{
    self = [super init];
    if (self)
    {
#if TARGET_OS_IPHONE
        self.machineName = [[UIDevice currentDevice] name];
#elif TARGET_OS_MAC
        // Dunno. Use SCDynamicStoreCopyComputerName?
        self.machineName = @"Unnamed Mac";
#else
        self.machineName = @"Unnamed Machine";
#endif
        client = theClient;
        sender = [NSNumber numberWithInt:0];
    }
    return self;
}

- (id)initWithHost:(NSString *)host andPort:(uint16_t)port
{
    return [self initWithMediatorClient:[[GNMediatorClient alloc] initWithHost:host onPort:port]];
}

- (id)init
{
    return [self initWithMediatorClient:[[GNMediatorClient alloc] init]];
}

#pragma mark - Private Methods
- (GNNetworkRequest *)newSendRequestTo:(NSString *)machine command:(id<GNNetworkMessageProtocol>)command
{
    NSDictionary *serializedCommand = [command jsonRPCObject];
    NSArray *params = [NSArray arrayWithObjects:machine, serializedCommand, sender, nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_SEND andParameters:params];
    return request;
}

- (GNNetworkRequest *)newRequestTo:(NSString *)machine command:(id<GNNetworkMessageProtocol>)command
{
    NSDictionary *serializedCommand = [command jsonRPCObject];
    NSArray *params = [NSArray arrayWithObjects:machine, serializedCommand, sender, nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_REQUEST andParameters:params];
    return request;
}

- (void)invokeCallback:(GNClientCallback)callback withMessage:(id<GNNetworkMessageProtocol>)msg
{
    if (![msg isResponse])
    {
        callback(NO, [NSDictionary dictionaryWithObjectsAndKeys:@"Unexpected data", @"reason", nil]);
        return;
    }
    GNNetworkResponse *response = (GNNetworkResponse *)msg;
    
    NSLog(@"%d", [response isError]);
    if ([response isError])
        callback(NO, response.error);
    else
        callback(YES, [NSDictionary dictionaryWithDictionary:response.result]);
}

#pragma mark - Public Properties

- (NSString *)machineType
{
    NSString *type = [[[UIDevice currentDevice] name] stringByReplacingOccurrencesOfString:@" " withString:@""];
    return [NSString stringWithFormat:@"editor.genesis.iOS.%@", type];
}

- (BOOL)isConnected
{
    return client.isConnected;
}

#pragma mark - Public Methods

#pragma mark Connection
- (void)connectWithSSL:(BOOL)useSSL withCallback:(MediatorClientCallback)callback
{
    [client connectWithSSL:useSSL withBlock:^(NSError *error) {
        callback(error);
    }];
}

- (void)disconnect
{
    return [client disconnect];
}

#pragma mark Mediator Operations

- (void)registerWithUsername:(NSString *)theUsername
                 andPassword:(NSString *)thePassword
                withCallback:(GNClientCallback)callback
{
    NSArray *params = [NSArray arrayWithObjects:theUsername,
                       [thePassword SHA512HashString],
                       sender,
                       nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_REGISTER andParameters:params];
    [client request:request withCallback:^(id<GNNetworkMessageProtocol> msg) {
        [self invokeCallback:callback withMessage:msg];
    }];
}

- (NSString *)loginWithPassword:(NSString *)thePassword
                    forUsername:(NSString *)theUsername
                   withCallback:(GNClientCallback)callback
{
    return [self loginWithPasswordHash:[thePassword SHA512HashString] forUsername:theUsername withCallback:callback];
}

- (NSString *)loginWithPasswordHash:(NSString *)thePasswordHash
                        forUsername:(NSString *)theUsername
                       withCallback:(GNClientCallback)callback
{
    // [username, password_hash, machineName, machineType sender]
    NSArray *params = [NSArray arrayWithObjects:theUsername,
                       thePasswordHash,
                       self.machineName,
                       self.machineType,
                       sender,
                       nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_LOGIN andParameters:params];
    [client request:request withCallback:^(id<GNNetworkMessageProtocol> msg) {
        [self invokeCallback:callback withMessage:msg];
    }];
    return thePasswordHash;
}

- (void)getClientsWithCallback:(GNClientCallback)callback
{
    NSArray *params = [NSArray arrayWithObject:sender];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_CLIENTS andParameters:params];
    [client request:request withCallback:^(id<GNNetworkMessageProtocol> msg) {
        [self invokeCallback:callback withMessage:msg];
    }];
}

- (void)getBuildersWithCallback:(GNClientCallback)callback
{
    [self getClientsWithCallback:^(BOOL succeeded, NSDictionary *info) {
        if(succeeded)
        {
            NSMutableDictionary *builderClients = [[NSMutableDictionary alloc] init];
            NSDictionary *allClients = [info objectForKey:@"clients"];
            for (NSString *key in [allClients allKeys])
            {
                NSRange range = [key rangeOfString:@"builder."];
                if (range.location == 0) {
                    [builderClients setObject:[allClients objectForKey:key] forKey:key];
                }
            }
            NSMutableDictionary *newInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
            [newInfo setObject:builderClients forKey:@"builders"];
            info = newInfo;
        }
        callback(succeeded, info);
    }];
}

#pragma mark Builder operations
- (void)getProjectsFromBuilder:(NSString *)builder
                  withCallback:(GNClientCallback)callback
{
    NSArray *params = [NSArray arrayWithObjects:sender, nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_PROJECTS andParameters:params];
    GNNetworkRequest *sendRequest = [self newRequestTo:builder command:request];
    [client request:sendRequest withCallback:^(id<GNNetworkMessageProtocol> msg) {
        [self invokeCallback:callback withMessage:msg];
    }];
}

- (void)getFilesFromBuilder:(NSString *)builder
                 forProject:(NSString *)project
               withCallback:(GNClientCallback)callback
{
    NSArray *params = [NSArray arrayWithObjects:project, sender, nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_FILES andParameters:params];
    GNNetworkRequest *sendRequest = [self newRequestTo:builder command:request];
    [client request:sendRequest withCallback:^(id<GNNetworkMessageProtocol> msg) {
        [self invokeCallback:callback withMessage:msg];
    }];
}

- (void)downloadFile:(NSString *)filepath
         fromBuilder:(NSString *)builder
          andProject:(NSString *)project
        withCallback:(GNClientCallback)callback
{
    NSArray *params = [NSArray arrayWithObjects:project, filepath, sender, nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_DOWNLOAD andParameters:params];
    GNNetworkRequest *sendRequest = [self newRequestTo:builder command:request];
    [client request:sendRequest withCallback:^(id<GNNetworkMessageProtocol> msg) {
        [self invokeCallback:callback withMessage:msg];
    }];
}

- (void)uploadFile:(NSString *)filepath
         toBuilder:(NSString *)builder
        andProject:(NSString *)project
      withContents:(NSString *)contents
      withCallback:(GNClientCallback)callback
{
    NSArray *params = [NSArray arrayWithObjects:project, filepath, contents, sender, nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_UPLOAD andParameters:params];
    GNNetworkRequest *sendRequest = [self newRequestTo:builder command:request];
    [client request:sendRequest withCallback:^(id<GNNetworkMessageProtocol> msg) {
        [self invokeCallback:callback withMessage:msg];
    }];
}

- (void)performAction:(NSString *)action
            toBuilder:(NSString *)builder
           andProject:(NSString *)project
   withStreamCallback:(GNClientCallback)streamCallback
{
    NSArray *params = [NSArray arrayWithObjects:project, action, sender, nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_PERFORM andParameters:params];
    GNNetworkRequest *sendRequest = [self newRequestTo:builder command:request];
    [client request:sendRequest withCallback:^(id<GNNetworkMessageProtocol> msg) {
        if (![msg isNotification])
        {
            NSLog(@"Invalid message for perform action. Expected notification message.");
            streamCallback(NO, [NSDictionary dictionaryWithObjectsAndKeys:@"Unexpected message", @"reason", nil]);
            return;
        }
        // change depending on type of stream.
        BOOL isSuccessful = NO;
        GNNetworkNotification *notification = (GNNetworkNotification *)msg;
        NSMutableDictionary *info = nil;
        if (notification.name == GN_STREAM)
        {
            NSString *project = [notification.params objectAtIndex:0];
            NSString *contents = [notification.params objectAtIndex:1];
            // always +1 to params size because of sender arg
            isSuccessful = project && contents && [notification.params count] == 3;
            info = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"stream", @"name",
                    project, @"project",
                    contents, @"contents",
                    nil];
        }
        else if (notification.name == GN_STREAM_EOF)
        {
            NSString *project = [notification.params objectAtIndex:0];
            // always +1 to params size because of sender arg
            isSuccessful = project && [notification.params count] == 2;
            info = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"stream_eof", @"name",
                    project, @"project",
                    nil];
        }
        else if (notification.name == GN_RETURN_CODE)
        {
            NSString *project = [notification.params objectAtIndex:0];
            NSNumber *returnCode = [notification.params objectAtIndex:1];
            // always +1 to params size because of sender arg
            isSuccessful = project && returnCode != nil && [notification.params count] == 3;
            info = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"return_code", @"name",
                    project, @"project",
                    returnCode, @"return_code",
                    nil];
        }
        else
        {
            info = [NSDictionary dictionaryWithObjectsAndKeys:@"Unknown notification", @"reason", nil];
        }
        streamCallback(isSuccessful, info);
    }];
}

- (void)cancelActionForProject:(NSString *)project
                   fromBuilder:(NSString *)builder
                  withCallback:(GNClientCallback)callback
{
    NSArray *params = [NSArray arrayWithObjects:project, sender, nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_CANCEL andParameters:params];
    GNNetworkRequest *sendRequest = [self newRequestTo:builder command:request];
    [client request:sendRequest withCallback:^(id<GNNetworkMessageProtocol> msg) {
        [self invokeCallback:callback withMessage:msg];
    }];
}

- (void)inputString:(NSString *)string
          toBuilder:(NSString *)builder
         andProject:(NSString *)project
       withCallback:(GNClientCallback)callback
{
    NSArray *params = [NSArray arrayWithObjects:project, string, sender, nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_INPUT andParameters:params];
    GNNetworkRequest *sendRequest = [self newRequestTo:builder command:request];
    [client request:sendRequest withCallback:^(id<GNNetworkMessageProtocol> msg) {
        [self invokeCallback:callback withMessage:msg];
    }];
}

@end
