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

// Genesis Network Error Codes
typedef enum {
    // global error codes
    kGNServerError = 0,
    kGNBadRequest = 1,
    kGNProjectNotFound = 10,
    kGNFileNotFound = 11,
    // codes for register
    kGNUsernameTaken = 100,
    kGNInvalidUsername = 101,
    kGNInvalidPassword = 102,
    // codes for logging in
    kGNBadAuth = 103,
    kGNMachineConflict = 104,
    kGNInvalidMachine = 105,
    kGNInvalidType = 106,
    // codes for send / request
    kGNUnknownMachine = 107,
    // codes for perform
    kGNActionNotFound = 108,
    kGNActionConflict = 109,
    // codes for input and cancel
    kGNNoActivity = 110,
} GNErrorCode;

@protocol GNNetworkManagerDelegate <NSObject>

@optional
// initialization phase
- (void)didConnectToMediatorWithError:(NSError *)error;
- (void)didAuthenticateWithError:(NSError *)error;
- (void)didRegisterWithError:(NSError *)error;
- (NSString *)selectFromBuilders:(NSArray *)builders error:(NSError *)error;

- (void)didReceiveProjects:(NSArray *)projects error:(NSError *)error;
- (void)didReceiveFiles:(NSArray *)files forBranch:(NSString *)branch forProject:(NSString *)projectName error:(NSError *)error;
- (void)didReceiveBranches:(NSArray *)branches headBranch:(NSString *)headBranch forProject:(NSString *)projectName error:(NSError *)error;
- (void)didDownloadFile:(NSString *)filepath withContents:(NSString *)contents forProject:(NSString *)projectName error:(NSError *)error;
- (void)didReceiveStatus:(NSString *)currentActivity error:(NSError *)error;
- (void)didUploadFile:(NSString *)filepath forProject:(NSString *)project error:(NSError *)error;

- (void)didPerformAction:(NSString *)action forProject:(NSString *)project error:(NSError *)error;

// TODO:
// - git
// - cancel
// - input
// - diff_stats
// - stage_file
// - commit

// TODO:
// - receive stream events

@end
