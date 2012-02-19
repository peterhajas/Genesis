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
#import "NSData+GNZlib.h"
#import "JSONKit.h"

#define TAG_VERSION 1
#define TAG_MESSAGE_LENGTH 2
#define TAG_MESSAGE_BODY 3

#define SUPPORTED_VERSION 1

@implementation GNMediatorClient

static dispatch_queue_t socketQueue;

+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        socketQueue = dispatch_queue_create("GNMediatorClientSocketQueue", NULL);
    }
}

@synthesize connectionTimeout, host, port, serverVersion;

- (id)init
{
    return [self initWithHost:GN_MEDIATOR_HOST onPort:GN_MEDIATOR_PORT];
}

- (id)initWithHost:(NSString *)hostAddr onPort:(uint16_t)portNum
{
    self = [super init];
    if(self)
    {
        self.connectionTimeout = 30;
        self.host = hostAddr;
        self.port = portNum;
        self.serverVersion = 0;
        sslEnabled = NO;
        expectedMessageLength = 0;

        socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    }
    
    return self;
}

- (BOOL)connectWithBlock:(MediatorClientCallback)doBlock useSSL:(BOOL)isSecure
{
    NSError *error = nil;
    if(![socket connectToHost:self.host onPort:self.port withTimeout:self.connectionTimeout error:&error])
    {
        doBlock(error);
        return NO;
    }
    
    sslEnabled = isSecure;
    connectCallback = doBlock;
    
    return YES;
}

- (void)request:(id<GNNetworkMessageProtocol>)request success:(MediatorClientCallback)doBlock
{
    
}

#pragma mark Error Codes

- (NSError *)errorWithCode:(NSInteger)errorCode
{
    return [NSError errorWithDomain:GN_NETWORK_ERROR_DOMAIN code:errorCode userInfo:nil];
}

- (NSError *)errorWithCode:(NSInteger)errorCode andReason:(NSString *)reason
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:reason, NSLocalizedDescriptionKey, nil];
    return [NSError errorWithDomain:GN_NETWORK_ERROR_DOMAIN code:errorCode userInfo:userInfo];
}

#pragma mark Processing Data

- (void)startReadVersion:(GCDAsyncSocket *)sock
{
    [sock readDataToLength:sizeof(uint16_t) withTimeout:-1 tag:TAG_VERSION];
}

- (BOOL)readVersionFromData:(NSData *)data
{
    if([data length] != sizeof(uint8_t))
    {
        NSLog(@"Invalid data for version");
        return NO;
    }
    
    uint16_t *value = (uint16_t*)[data bytes];
    *value = ntohs(*value);
    self.serverVersion = *value;
    
    NSLog(@"Server API Version: %hu", self.serverVersion);
    return SUPPORTED_VERSION == self.serverVersion;
}

- (BOOL)readMessageLengthFromData:(NSData *)data
{
    if([data length] != sizeof(uint16_t))
    {
        NSLog(@"Invalid message length");
        return NO;
    }
    
    uint16_t *value = (uint16_t *)[data bytes];
    *value = ntohs(*value);
    expectedMessageLength = *value;
    
    NSLog(@"Message Length: %hu", *value);
    return YES;
}

- (id)readMessageBodyFromData:(NSData *)data
{
    if ([data length] != expectedMessageLength)
    {
        NSLog(@"Expected message length (%hu) does not match actual (%u)", expectedMessageLength, [data length]);
        return nil;
    }
    // gunzip data
    NSData *gunzipData = [data gunzipData];
    if (!gunzipData){
        NSLog(@"Message was not in gzip format.");
        return nil;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:gunzipData encoding:NSASCIIStringEncoding];
    // parse as json!
    id object = [jsonString objectFromJSONStringWithParseOptions:JKParseOptionUnicodeNewlines];
    
    if (![object isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Message was not an object (aka, NSDictionary)");
        return nil;
    }
    // validate
    id obj = [[GNNetworkResponse alloc] initWithDictionary:object];
    if(![obj isValid])
    {
        // try parsing as response
        obj = [[GNNetworkNotification alloc] initWithDictionary:object];
        if(![obj isValid])
        {
            return nil; // failure
        }
    }
    return obj;
}

#pragma mark Socket Delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)hostAddr port:(uint16_t)portNum
{
    NSLog(@"Connected to %@ from %hu", hostAddr, portNum);
    
    
    [sock performBlock:^{
        if([sock enableBackgroundingOnSocket])
        {
            NSLog(@"Enabled backgrounding socket.");
        }
        else
        {
            NSLog(@"Failed to enable backgrounding socket.");
        }
    }];
    
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
        [self startReadVersion:sock];
    }
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    NSLog(@"isSecure = YES");
    [self startReadVersion:sock];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    id msg = nil;
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
                connectCallback([self errorWithCode:GN_ERROR_BAD_VERSION]);
                [sock disconnect];
            }
            break;
        case TAG_MESSAGE_LENGTH:
            if([self readMessageLengthFromData:data])
            {
                
            }
            else
            {
                NSLog(@"Bad message body");
                //[sock disconnect];
            }
        case TAG_MESSAGE_BODY:
            msg = [self readMessageBodyFromData:data];
            if (msg)
            {
                // 
            }
            else
            {
                NSLog(@"Bad message body.");
                //[sock disconnect];
            }
        default:
            // do something with garbage data??
            break;
    }
}

@end
