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
#import "GNAPIClient.h"
#import "GNNetworkManagerDelegate.h"

@interface GNNetworkManager {
    BOOL useSSL;
    GNAPIClient *client;
}

// the object that handles all the responses
@property (nonatomic, strong) id<GNNetworkManagerDelegate> delegate;

// the current builder we're operating with
@property (nonatomic, strong) NSString *builder;

// When trying to log in, try to register.
@property (nonatomic, assign) BOOL autoregister;

- (id)initWithHost:(NSString *)theHost andPort:(uint16_t)port;
- (id)initWithHost:(NSString *)theHost andPort:(uint16_t)port withSSL:(BOOL)useSSL;

// initiate connection
- (id)connectInBackground;
- (id)connectInBackgroundWithUsername:(NSString *)username andPassword:(NSString *)password;

// after initial connection
- (void)registerWithUsername:(NSString *)username andPassword:(NSString *)password;
- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password;

// various actions
- (void)requestProjects;
- (void)requestFilesForProject:(NSString *)project;
- (void)downloadFile:(NSString *)filepath forProject:(NSString *)project;
- (void)uploadFile:(NSString *)filepath withContents:(NSString *)contents forProject:(NSString *)project;
// TODO:
- (void)requestBranchesForProject:(NSString *)project;

@end
