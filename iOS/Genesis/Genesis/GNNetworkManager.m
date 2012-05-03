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

@synthesize delegate;
@synthesize autoregister;
@synthesize builder;

#pragma mark - Constructors

- (id)initWithHost:(NSString *)theHost onPort:(uint16_t)port withSSL:(BOOL)secure
{
    if (self = [super init])
    {
        client = [[GNAPIClient alloc] initWithHost:theHost andPort:port];
        useSSL = secure;
        self.autoregister = YES;
        networkActivityCounter = 0;
    }
    return self;
}

#pragma mark - Helper methods

- (void)incrementNetworkActivityCounter
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = (++networkActivityCounter > 0);
    NSLog(@"inc %d", networkActivityCounter);
}

- (void)decrementNetworkActivityCounter
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = (--networkActivityCounter > 0);
    NSLog(@"dec %d - %d", networkActivityCounter, [UIApplication sharedApplication].networkActivityIndicatorVisible);
}

- (NSError *)errorFromDictionary:(NSDictionary *)info
{
    return [NSError errorWithDomain:GN_NETWORK_ERROR_DOMAIN
                               code:[[info objectForKey:@"code"] intValue]
                           userInfo:info];
}

- (NSError *)errorUnlessSucceeded:(BOOL) succeeded withDictionary:(NSDictionary *)info
{
    NSError *error = nil;
    if (!succeeded)
    {
        error = [self errorFromDictionary:info];
    }
    return error;
}

- (void)assertBuilder
{
    return;
    // Do nothing for now.
    assert(self.builder != nil);
    /*
    if (self.builder == nil)
    {
        NSLog(@"ERROR: builder not specified!");
    }
     */
}

- (void)getBuilders
{
    [self incrementNetworkActivityCounter];
    [client getBuildersWithCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        NSArray *builders = nil;
        if (error != nil)
        {
            builders = [NSMutableArray new];
        }
        else
        {
            builders = [[info objectForKey:@"builders"] allKeys];
            NSLog(@"builders: %@", builders);
        }
        
        if ([delegate respondsToSelector:@selector(selectFromBuilders:error:)])
        {
            self.builder = [delegate selectFromBuilders:builders error:error];
        }
        else if (error == nil && [builders count] > 0)
        {
            self.builder = [builders objectAtIndex:0];
        }
        else
        {
            NSLog(@"No builders found!");
            return;
        }
        [self requestProjects];
        [self decrementNetworkActivityCounter];
    }];
}

#pragma mark - Basic Operations

- (id)connectInBackground
{
    [self incrementNetworkActivityCounter];
    [client connectWithSSL:useSSL withCallback:^(NSError *error) {
        if ([delegate respondsToSelector:@selector(didConnectToMediatorWithError:)])
        {
            [delegate didConnectToMediatorWithError:error];
        }
        [self decrementNetworkActivityCounter];
    }];
    return self;
}

- (id)connectInBackgroundWithUsername:(NSString *)username andPassword:(NSString *)password
{
    [self incrementNetworkActivityCounter];
    [client connectWithSSL:useSSL withCallback:^(NSError *error) {
        if ([delegate respondsToSelector:@selector(didConnectToMediatorWithError:)])
        {
            [delegate didConnectToMediatorWithError:error];
        }
        if (!error)
        {
            [self loginWithUsername:username andPassword:password];
        }
        [self decrementNetworkActivityCounter];
    }];
    return self;
}

- (void)registerWithUsername:(NSString *)username andPassword:(NSString *)password
{
    [self incrementNetworkActivityCounter];
    [client registerWithUsername:username
                     andPassword:password
                    withCallback:^(BOOL succeeded, NSDictionary *info) {
                        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
                        if ([delegate respondsToSelector:@selector(didRegisterWithError:error:)])
                        {
                            [delegate didRegisterWithError:error];
                        }
                        [self decrementNetworkActivityCounter];
                    }];
}

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password
{
    [self incrementNetworkActivityCounter];
    if (self.autoregister)
    {
        NSLog(@"Registering - %@ %@", username, password);
        [client registerWithUsername:username
                         andPassword:password
                        withCallback:^(BOOL succeeded, NSDictionary *info) {
                            NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
                            if ([delegate respondsToSelector:@selector(didReceiveProjects:error:)])
                            {
                                [delegate didRegisterWithError:error];
                            }
                            [self incrementNetworkActivityCounter];
                            [client loginWithPassword:password
                                          forUsername:username
                                         withCallback:^(BOOL succeeded, NSDictionary *info) {
                                             NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
                                             if ([delegate respondsToSelector:@selector(didAuthenticateWithError:)])
                                             {
                                                 [delegate didAuthenticateWithError:error];
                                             }
                                             [self getBuilders];
                                             [self decrementNetworkActivityCounter];
                            }];
                            [self decrementNetworkActivityCounter];
        }];
    }
    else
    {
        [client loginWithPassword:password forUsername:username withCallback:^(BOOL succeeded, NSDictionary *info) {
            NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
            if ([delegate respondsToSelector:@selector(didAuthenticateWithError:)])
            {
                [delegate didAuthenticateWithError:error];
            }
            [self getBuilders];
            [self decrementNetworkActivityCounter];
        }];
    }
}

#pragma mark Pimary Actions

- (void)requestProjects
{
    [self assertBuilder];
    [self incrementNetworkActivityCounter];
    [client getProjectsFromBuilder:self.builder withCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        NSArray *projects = nil;
        if (error)
        {
            projects = [NSArray array];
        }
        else
        {
            projects = [info objectForKey:@"projects"];
        }
        if ([delegate respondsToSelector:@selector(didReceiveProjects:error:)])
        {
            [delegate didReceiveProjects:projects error:error];
        }
        [self decrementNetworkActivityCounter];
    }];
}

- (void)requestFilesForProject:(NSString *)project
{
    [self assertBuilder];
    [self incrementNetworkActivityCounter];
    [client getFilesFromBuilder:self.builder forProject:project withCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        NSArray *files = [NSArray array];
        NSString *branch = nil;
        if (!error)
        {
            files = [info objectForKey:@"files"];
            branch = [info objectForKey:@"branch"];
        }
        if ([delegate respondsToSelector:@selector(didReceiveFiles:forBranch:forProject:error:)])
        {
            [delegate didReceiveFiles:files forBranch:branch forProject:project error:error];
        }
        [self decrementNetworkActivityCounter];
    }];
}

- (void)requestBranchesForProject:(NSString *)project
{
    [self incrementNetworkActivityCounter];
    [client getBranchesFromBuilder:self.builder forProject:project withCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        NSArray *branches = [NSArray array];
        NSString *head = nil;
        if (error == nil)
        {
            branches = [info objectForKey:@"branches"];
            head = [info objectForKey:@"head"];
        }
        if ([delegate respondsToSelector:@selector(didReceiveBranches:headBranch:forProject:error:)])
        {
            [delegate didReceiveBranches:branches headBranch:head forProject:project error:error];
        }
        [self decrementNetworkActivityCounter];
    }];
}

- (void)uploadFile:(NSString *)filepath withContents:(NSString *)contents forProject:(NSString *)project
{
    [self assertBuilder];
    [self incrementNetworkActivityCounter];
    [client uploadFile:filepath toBuilder:self.builder andProject:project withContents:contents withCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        if ([delegate respondsToSelector:@selector(didUploadFile:forProject:error:)])
        {
            [delegate didUploadFile:filepath forProject:project error:error];
        }
        [self decrementNetworkActivityCounter];
    }];
}

- (void)downloadFile:(NSString *)filepath forProject:(NSString *)project
{
    [self assertBuilder];
    [self incrementNetworkActivityCounter];
    [client downloadFile:filepath fromBuilder:self.builder andProject:project withCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        NSString *contents = nil;
        if (error == nil)
        {
            contents = [info objectForKey:@"contents"];
        }
        else
        {
            NSLog(@"Failed to download file: %@", error);
        }
        
        if ([delegate respondsToSelector:@selector(didDownloadFile:withContents:forProject:error:)])
        {
            [delegate didDownloadFile:filepath withContents:contents forProject:project error:error];
        }
        [self decrementNetworkActivityCounter];
    }];
}

@end
