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

#import "GNNetworkResponse.h"
#import "GNNetworkMessageKeys.h"

@implementation GNNetworkResponse

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self)
    {
        dict = dictionary;
    }
    return self;
}

- (id)error
{
    return [dict objectForKey:ERROR_KEY];
}

- (id)result
{
    return [dict objectForKey:RESULT_KEY];
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
    return self.identifier && (self.result || self.error);
}

- (BOOL)isError
{
    return self.result == nil && self.error != nil;
}

- (BOOL)isResponse
{
    return YES;
}

- (BOOL)isNotification
{
    return NO;
}

- (BOOL)isRequest
{
    return NO;
}

- (NSDictionary *)jsonRPCObject
{
    return dict;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<GNNetworkResponse(id=%@, result=%@, error=%@)>",
            self.identifier, self.result, self.error, nil];
}

@end
