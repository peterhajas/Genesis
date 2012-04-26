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
    }
    return self;
}

#pragma mark - Helper methods

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
    [client getBuildersWithCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        NSMutableArray *builders = nil;
        if (error != nil)
        {
            builders = [NSMutableArray new];
        }
        if ([delegate respondsToSelector:@selector(selectFromBuilders:error:)])
        {
            self.builder = [delegate selectFromBuilders:builders error:error];
        }
        else if (error == nil && [builders count] > 0)
        {
            self.builder = [builders objectAtIndex:0];
        }
    }];
}

#pragma mark - Basic Operations

- (id)connectInBackground
{
    [client connectWithSSL:useSSL withCallback:^(NSError *error) {
        [delegate didConnectToMediatorWithError:error];
    }];
    return self;
}

- (id)connectInBackgroundWithUsername:(NSString *)username andPassword:(NSString *)password
{
    [client connectWithSSL:useSSL withCallback:^(NSError *error) {
        [delegate didConnectToMediatorWithError:error];
        if (error != nil)
        {
            [self loginWithUsername:username andPassword:password];
        }
    }];
    return self;
}

- (void)registerWithUsername:(NSString *)username andPassword:(NSString *)password
{
    [client registerWithUsername:username
                     andPassword:password
                    withCallback:^(BOOL succeeded, NSDictionary *info) {
                        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
                        [delegate didRegisterWithError:error];
                    }];
}

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password
{
    if (self.autoregister)
    {
        [client registerWithUsername:username
                         andPassword:password
                        withCallback:^(BOOL succeeded, NSDictionary *info) {
                            NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
                            [delegate didRegisterWithError:error];
                            [client loginWithPassword:username
                                          forUsername:password
                                         withCallback:^(BOOL succeeded, NSDictionary *info) {
                                             NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
                                             [delegate didAuthenticateWithError:error];
                                             [self getBuilders];
                            }];
        }];
    }
    else
    {
        [client loginWithPassword:password forUsername:username withCallback:^(BOOL succeeded, NSDictionary *info) {
            NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
            [delegate didAuthenticateWithError:error];
            [self getBuilders];
        }];
    }
}

#pragma mark Pimary Actions

- (void)requestProjects
{
    [self assertBuilder];
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
        [delegate didReceiveProjects:projects error:error];
    }];
}

- (void)requestFilesForProject:(NSString *)project
{
    [self assertBuilder];
    [client getFilesFromBuilder:self.builder forProject:project withCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        NSArray *files = [NSArray array];
        NSString *branch = nil;
        if (!error)
        {
            files = [info objectForKey:@"files"];
            branch = [info objectForKey:@"branch"];
        }
        [delegate didReceiveFiles:files forBranch:branch forProject:project error:error];
    }];
}

- (void)requestBranchesForProject:(NSString *)project
{
    [client getBranchesFromBuilder:self.builder forProject:project withCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        NSArray *branches = [NSArray array];
        NSString *head = nil;
        if (error == nil)
        {
            branches = [info objectForKey:@"branches"];
            head = [info objectForKey:@"head"];
        }
        [delegate didReceiveBranches:branches headBranch:head forProject:project error:error];
    }];
}

- (void)uploadFile:(NSString *)filepath withContents:(NSString *)contents forProject:(NSString *)project
{
    [self assertBuilder];
    [client uploadFile:filepath toBuilder:self.builder andProject:project withContents:contents withCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        [delegate didUploadFile:filepath forProject:project error:error];
    }];
}

- (void)downloadFile:(NSString *)filepath forProject:(NSString *)project
{
    [self assertBuilder];
    [client downloadFile:filepath fromBuilder:self.builder andProject:project withCallback:^(BOOL succeeded, NSDictionary *info) {
        NSError *error = [self errorUnlessSucceeded:succeeded withDictionary:info];
        NSString *contents = nil;
        if (error == nil)
        {
            contents = [info objectForKey:@"contents"];
        }
        [delegate didDownloadFile:filepath withContents:contents forProject:project error:error];
    }];
}

@end
