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

#import "GNMediatorClient.h"
#import "NSData+GNNSDataCategory.h"

#define TAG_VERSION 1
#define TAG_MESSAGE_LENGTH 2
#define TAG_MESSAGE_BODY 3

#define SUPPORTED_VERSION 2

NSString * const GN_NETWORK_ERROR_DOMAIN = @"genesis";
const NSInteger GNErrorBadVersion = 1;
const NSInteger GNErrorBadProtocol = 2;

@implementation GNMediatorClient

#pragma mark - Initialization

@synthesize connectionTimeout;
@synthesize host, port;
@synthesize serverVersion;
@synthesize compress;


- (id)initWithHost:(NSString *)hostAddr onPort:(uint16_t)portNum
{
    self = [super init];
    if(self)
    {
        self.connectionTimeout = 10;
        self.host = hostAddr;
        self.port = portNum;
        self.serverVersion = 0;
        self.compress = YES;
        sslEnabled = NO;

        socket = nil;
        messageHandlers = nil;
        fallbackMessageHandler = nil;
    }
    
    return self;
}

#pragma mark - Error Codes

- (NSError *)errorWithCode:(NSInteger)errorCode
{
    return [NSError errorWithDomain:GN_NETWORK_ERROR_DOMAIN code:errorCode userInfo:nil];
}

- (NSError *)errorWithCode:(NSInteger)errorCode andReason:(NSString *)reason
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:reason, NSLocalizedDescriptionKey, nil];
    return [NSError errorWithDomain:GN_NETWORK_ERROR_DOMAIN code:errorCode userInfo:userInfo];
}

#pragma mark - Processing Data

- (BOOL)readVersionFromData:(NSData *)data
{
    uint32_t size = sizeof(uint16_t);
    if([data length] != size)
    {
        NSLog(@"Invalid data length for version (got %u; expected %u)", [data length], size);
        return NO;
    }
    
    uint16_t *value = (uint16_t*)[data bytes];
    *value = ntohs(*value);
    self.serverVersion = *value;
    
    NSLog(@"Server API Version: %@ = %hu", data, self.serverVersion);
    return SUPPORTED_VERSION == self.serverVersion;
}

- (uint32_t)readMessageLengthFromData:(NSData *)data
{
    if([data length] != sizeof(uint32_t))
    {
        NSLog(@"Invalid message length");
        return 0;
    }
    
    uint32_t *value = (uint32_t *)[data bytes];
    *value = ntohl(*value);
    
    return *value;
}

- (id)readMessageBodyFromData:(NSData *)data
{
    // gunzip data
    if (self.compress)
    {
        data = [data zlibInflate];
        if (!data)
        {
            NSLog(@"Message was not in compressed format.");
            return nil;
        }
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    id object = [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:nil];
    if (![object isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Message was not an object (aka, NSDictionary): %@", object);
        return nil;
    }
    // validate
    id<GNNetworkMessageProtocol> obj = [[GNNetworkResponse alloc] initWithDictionary:object];
    if(![obj isValid])
    {
        // try parsing as response
        obj = [[GNNetworkNotification alloc] initWithDictionary:object];
        if(![obj isValid])
        {
            NSLog(@"Bad message: %@", jsonString);
            return nil; // failure
        }
    }
    return obj;
}

- (void)startReadVersion
{
    NSLog(@"start reading version");
    [socket readDataToLength:sizeof(uint16_t) withTimeout:-1 tag:TAG_VERSION];
}

- (void)startReadMessage
{
    [socket readDataToLength:sizeof(uint32_t) withTimeout:-1 tag:TAG_MESSAGE_LENGTH];
}

- (void)startReadMessageBodyWithLength:(uint32_t)messageLength
{
    [socket readDataToLength:messageLength withTimeout:-1 tag:TAG_MESSAGE_BODY];
}

- (void)dispatchMessage:(id<GNNetworkMessageProtocol>)message
{
    if ([message identifier] && [messageHandlers objectForKey:[message identifier]])
    {
        id obj = [messageHandlers objectForKey:[message identifier]];
        if (obj)
        {
            MediatorMessageHandler handler = (MediatorMessageHandler)obj;
            handler(message);
            [messageHandlers removeObjectForKey:[message identifier]];
            return;
        }
    }
    
    // use generic handler
    if (fallbackMessageHandler)
    {
        NSLog(@"Using fallback");
        fallbackMessageHandler(message);
        return;
    }
    
    NSLog(@"Unhandled message being dropped: %@", message);
}

#pragma mark - Private Methods

- (NSData *)dataFromDictionary:(NSDictionary *)dictionary
{
    NSError* error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:0
                                                         error:&error];
    
    if (error)
    {
        NSLog(@"Error in -[dataFromDictionary:] : %@ domain: %@", error, [error domain]);
    }
    
    if (self.compress)
    {
        NSData *compressedData = [jsonData zlibDeflate];
        assert(compressedData != nil);
        return compressedData;
    }
    return jsonData;
}

- (void)disconnectWithError:(NSError *)error
{
    [socket disconnect];
    if (connectCallback)
    {
        connectCallback(error);
    }
    if (disconnectCallback)
    {
        disconnectCallback(error);
    }
}

#pragma mark - Public Methods

- (BOOL)isConnected
{
    return [socket isConnected];
}

- (BOOL)connectWithSSL:(BOOL)isSecure withBlock:(MediatorClientCallback)doBlock
{
    socket = [[AsyncSocket alloc] initWithDelegate:self];
    messageHandlers = [NSMutableDictionary new];
    
    sslEnabled = isSecure;
    connectCallback = doBlock;
    
    NSError *error = nil;
    [socket connectToHost:self.host onPort:self.port withTimeout:self.connectionTimeout error:&error];
    
    NSLog(@"Starting connection (timeout: %f)", self.connectionTimeout);
    
    return error == nil;
}

- (void)disconnect
{
    [self disconnectWithError:nil];
}

- (void)setDisconnectBlock:(MediatorClientCallback)onDisconnectBlock
{
    disconnectCallback = onDisconnectBlock;
}

- (void)onMessageIdentifierRecieved:(NSString *)identifier doCallback:(MediatorMessageHandler)doBlock
{
    if(identifier && doBlock)
    {
        [messageHandlers setObject:doBlock forKey:identifier];
        NSLog(@"Added handler to collection.");
    }
    [self startReadMessage];
}

- (void)request:(id<GNNetworkMessageProtocol>)request withCallback:(MediatorMessageHandler)doBlock
{
    [self onMessageIdentifierRecieved:[request identifier] doCallback:doBlock];
    [self send:request];
}

- (void)send:(id<GNNetworkMessageProtocol>)request
{
    NSLog(@"Request ID: %@", [request identifier]);
    NSData *msgData = [self dataFromDictionary:[request jsonRPCObject]];
    uint32_t size = htonl(msgData.length);
    NSData *sizeData = [[NSData alloc] initWithBytes:&size length:sizeof(uint32_t)];
    [socket writeData:sizeData withTimeout:-1 tag:0];
    [socket writeData:msgData withTimeout:-1 tag:0];
}

- (void)setFallbackMessageHandler:(MediatorMessageHandler)doBlock
{
    fallbackMessageHandler = doBlock;
}

#pragma mark - Socket Delegate

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog(@"Disconnected: %@", err);
    [self disconnectWithError:err];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)hostAddr port:(uint16_t)portNum
{
    NSLog(@"Connected to %@ from %hu", hostAddr, portNum);
    
    if(sslEnabled)
    {
        NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
        
        [settings setObject:self.host forKey:(NSString *)kCFStreamSSLPeerName];
        // Allow expired certificates
        //[settings setObject:[NSNumber numberWithBool:YES]
        //			 forKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
        
        // Allow self-signed certificates
        [settings setObject:[NSNumber numberWithBool:YES]
        			 forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
        
        // In fact, don't even validate the certificate chain
        //[settings setObject:[NSNumber numberWithBool:NO]
        //			 forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
        
        NSLog(@"Running securely with settings: %@", settings);
        
        [sock startTLS:settings];
    }
    else
    {
        [self startReadVersion];
    }
}

- (void)onSocketDidSecure:(AsyncSocket *)sock
{
    NSLog(@"isSecure = YES");
    [self startReadVersion];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    id<GNNetworkMessageProtocol> msg = nil;
    uint32_t size = 0;
    switch(tag)
    {
        case TAG_VERSION:
            if([self readVersionFromData:data])
            {
                connectCallback(nil);
            }
            else
            {
                NSLog(@"Disconnected - Bad Version format");
                [self disconnect];
                connectCallback([self errorWithCode:GNErrorBadProtocol]);
            }
            connectCallback = nil;
            break;
        case TAG_MESSAGE_LENGTH:
            size = [self readMessageLengthFromData:data];
            if(size > 0)
            {
                [self startReadMessageBodyWithLength:size];
                NSLog(@"Got message size: %u", size);
            }
            else
            {
                NSLog(@"Bad message body");
                //[self disconnectWithError:];
            }
            break;
        case TAG_MESSAGE_BODY:
            msg = [self readMessageBodyFromData:data];
            if (msg)
            {
                NSLog(@"Dispatch Message: %@", msg);
                [self dispatchMessage:msg];
                // handle message! (call delegate?)
            }
            else
            {
                NSLog(@"Bad message body. (%u)", data.length);
                //[self disconnectWithError:];
            }
            break;
        default:
            NSLog(@"Data Dropped");
            // do something with garbage data??
            break;
    }
}

@end
