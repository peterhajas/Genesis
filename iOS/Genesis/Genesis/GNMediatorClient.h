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
#import "AsyncSocket.h"
#import "GNNetworkResponse.h"
#import "GNNetworkNotification.h"
#import "GNNetworkRequest.h"
#import "GNNetworkMessageProtocol.h"

#define GN_MEDIATOR_HOST @"localhost"
#define GN_MEDIATOR_PORT 8080


extern NSString * const GN_NETWORK_ERROR_DOMAIN;

extern const NSInteger GNErrorBadVersion;
extern const NSInteger GNErrorBadProtocol;

typedef void(^MediatorClientCallback)(NSError *error);
typedef void(^MediatorMessageHandler)(id<GNNetworkMessageProtocol>msg);

/*
 * Low-level client protocol to the Genesis Mediator server.
 * Use GNAPIClient if you want to higher-level variant.
 */
@interface GNMediatorClient : NSObject <AsyncSocketDelegate>
{
    AsyncSocket *socket;
    MediatorClientCallback connectCallback, disconnectCallback;
    MediatorMessageHandler fallbackMessageHandler;
    NSMutableDictionary *messageHandlers;
    uint16_t expectedMessageLength;
    BOOL sslEnabled;
}

@property (nonatomic) NSTimeInterval connectionTimeout;
@property (nonatomic, strong) NSString *host;
@property (nonatomic) uint16_t port;
@property (nonatomic) uint16_t serverVersion;
@property (nonatomic) BOOL compress;


- (id)init;
- (id)initWithHost:(NSString *)ipAddress onPort:(uint16_t)portNum;

- (void)setDisconnectBlock:(MediatorClientCallback)onDisconnectBlock;

- (BOOL)connectWithSSL:(BOOL)isSecure withBlock:(MediatorClientCallback)doBlock;
- (void)disconnect;
- (void)request:(id<GNNetworkMessageProtocol>)request withCallback:(MediatorMessageHandler)doBlock;
- (void)send:(id<GNNetworkMessageProtocol>)request;
- (void)setFallbackMessageHandler:(MediatorMessageHandler)handler;

@end
