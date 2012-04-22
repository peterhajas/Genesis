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

@synthesize apiClient;
@synthesize builders;

-(id)initWithHost:(NSString*)host andPort:(uint16_t)port username:(NSString*)username password:(NSString*)password
{
    self = [super init];
    if(self)
    {
        apiClient = [[GNAPIClient alloc] initWithHost:host andPort:port];
        [self connectWithUsername:username password:password];
        builders = [[NSMutableArray alloc] init];
        currentBuilder = nil;
    }
    return self;
}

-(void)connectWithUsername:(NSString*)username password:(NSString*)password
{
    [apiClient connectWithSSL:NO
                 withCallback:^(NSError* error)
     {
         if(error)
         {
             NSLog(@"error connecting: %@", error);
         }
         else
         {
             [self loginWithUsername:username password:password];
         }
     }];
}

-(void)loginWithUsername:(NSString*)username password:(NSString*)password
{
    [apiClient loginWithPassword:password
                     forUsername:username
                    withCallback:^(BOOL succeeded, NSDictionary* info)
     {
         if(succeeded)
         {
             [self grabBuilders];
         }
         else
         {
             NSLog(@"could not log in"); //TODO: error in a better way that the user can see
         }
     }];
}

-(void)grabBuilders
{
    [apiClient getBuildersWithCallback:^(BOOL succeeded, NSDictionary* info)
     {
         if(succeeded)
         {
             NSArray* buildersFromCall = [info valueForKey:@"builders"];
             for(NSString* builder in buildersFromCall)
             {
                 [builders addObject:builder];
             }
         }
         else
         {
             NSLog(@"could not grab builders");
         }
     }];
}

@end
