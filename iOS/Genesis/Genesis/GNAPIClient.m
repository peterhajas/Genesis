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

@synthesize isConnected=_isConnected;
@synthesize machineName;

#pragma mark - Constructors

- (id)initWithMediatorClient:(GNMediatorClient *)theClient
{
    self = [super init];
    if (self)
    {
        self.machineName = @"Genesis iOS Editor";
        client = theClient;
        _isConnected = NO;
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

#pragma mark - Public Properties

- (NSString *)machineType
{
    NSString *type = [[[UIDevice currentDevice] name] stringByReplacingOccurrencesOfString:@" " withString:@""];
    return [NSString stringWithFormat:@"editor.genesis.iOS.%@", type];
}

#pragma mark - Public Methods

- (void)connectWithSSL:(BOOL)useSSL withCallback:(MediatorClientCallback)callback
{
    [client connectWithSSL:useSSL withBlock:^(NSError *error) {
        _isConnected = (error == nil);
        callback(error);
    }];
}

- (void)disconnect
{
    return [client disconnect];
}

- (void)registerWithUsername:(NSString *)theUsername
                 andPassword:(NSString *)thePassword
                withCallback:(GNClientCallback)callback
{
    NSArray *params = [NSArray arrayWithObjects:theUsername,
                       [thePassword SHA512HashString],
                       [NSNumber numberWithInt:0],
                       nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_REGISTER
                                                         andParameters:params
                                                     andExpectResponse:YES];
    [client request:request withCallback:^(id<GNNetworkMessageProtocol> msg) {
        if (![msg isResponse])
        {
            callback(NO, [NSDictionary dictionaryWithObjectsAndKeys:@"Unexpected data", @"reason", nil]);
            return;
        }
        GNNetworkResponse *response = (GNNetworkResponse *)msg;
        
        if (![response isError])
            callback(YES, nil);
        else
            callback(NO, [NSDictionary dictionaryWithDictionary:response.error]);
    }];
}

- (void)loginWithUsername:(NSString *)theUsername
              andPassword:(NSString *)thePassword
             withCallback:(GNClientCallback)callback
{
    // [username, password_hash, machineName, machineType sender]
    NSArray *params = [NSArray arrayWithObjects:theUsername,
                       [thePassword SHA512HashString],
                       self.machineName,
                       self.machineType,
                       [NSNumber numberWithInt:0],
                       nil];
    GNNetworkRequest *request = [[GNNetworkRequest alloc] initWithName:GN_LOGIN
                                                         andParameters:params
                                                     andExpectResponse:YES];
    [client request:request withCallback:^(id<GNNetworkMessageProtocol> msg) {
        if (![msg isResponse])
        {
            callback(NO, [NSDictionary dictionaryWithObjectsAndKeys:@"Unexpected data", @"reason", nil]);
            return;
        }
        GNNetworkResponse *response = (GNNetworkResponse *)msg;
        
        if (![response isError])
            callback(YES, nil);
        else
            callback(NO, [NSDictionary dictionaryWithDictionary:response.error]);
    }];
}

- (void)getClientsWithCallback:(GNClientCallback)callback
{
    
}

@end
