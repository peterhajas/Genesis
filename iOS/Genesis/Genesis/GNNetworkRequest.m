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

#import "GNNetworkRequest.h"
#import "GNNetworkMessageKeys.h"

// probably needs a better place to be other than here...
NSString* generateUUID(void);

NSString* generateUUID(void){
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return uuidString;
}

@implementation GNNetworkRequest

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self)
    {
        dict = dictionary;
    }
    return self;
}

- (id)initWithName:(NSString *)name
     andParameters:(NSArray *)parameters
 andExpectResponse:(BOOL)expectsResponse
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:name, NAME_KEY,
                                parameters, PARAMETERS_KEY,
                                (expectsResponse ? generateUUID() : nil), ID_KEY,
                                nil];
    self = [self initWithDictionary:dictionary];
    return self;
}

- (id)params
{
    return [dict objectForKey:PARAMETERS_KEY];
}

- (NSString *)name
{
    return [dict objectForKey:NAME_KEY];
}

- (NSString *)identifier
{
    id obj = [dict objectForKey:ID_KEY];
    if(obj == nil)
        return nil;
    return (NSString *)obj;
}

- (BOOL)isValid
{
    return ![[dict objectForKey:ID_KEY] isKindOfClass:[NSString class]] && self.name && self.params;
}

- (BOOL)isResponse
{
    return NO;
}

- (BOOL)isNotification
{
    return NO;
}

- (BOOL)isRequest
{
    return YES;
}

- (NSDictionary *)jsonRPCObject
{
    return dict;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<GNNetworkRequest(id=%@, name=%@, params=%@)>",
            self.identifier, self.name, self.params, nil];
}

@end
