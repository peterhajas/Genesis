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

// generalized fields
extern NSString * const GN_ID_KEY;

// request fields
extern NSString * const GN_PARAMETERS_KEY;
extern NSString * const GN_NAME_KEY;

// response fields
extern NSString * const GN_RESULT_KEY;
extern NSString * const GN_ERROR_KEY;


// method names for mediator
extern NSString * const GN_LOGIN;
extern NSString * const GN_REGISTER;
extern NSString * const GN_SEND;
extern NSString * const GN_REQUEST;
extern NSString * const GN_CLIENTS;

// method names for builder
extern NSString * const GN_PROJECTS;
extern NSString * const GN_FILES;
extern NSString * const GN_DOWNLOAD;
extern NSString * const GN_UPLOAD;
extern NSString * const GN_PERFORM;
extern NSString * const GN_CANCEL;
extern NSString * const GN_INPUT;


// method names for editor (us)
extern NSString * const GN_STREAM;
extern NSString * const GN_STREAM_EOF;
extern NSString * const GN_RETURN_CODE;
