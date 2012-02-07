//
//  PHTextRange.m
//  TextViewTester
//
//  Created by Peter Hajas on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNTextRange.h"

@implementation GNTextPosition

@synthesize position;

@end

@implementation GNTextRange

-(id)initWithStartPosition:(NSUInteger)start endPosition:(NSUInteger)end
{
    self = [super init];
    if(self)
    {
        startPosition = [[GNTextPosition alloc] init];
        [startPosition setPosition:start];
        
        endPosition = [[GNTextPosition alloc] init];
        [endPosition setPosition:end];
    }
    return self;
}

-(UITextPosition*)start
{
    return startPosition;
}

-(UITextPosition*)end
{
    return endPosition;
}

-(NSRange)textRangeRange
{
    NSRange range;
    NSUInteger start = [startPosition position];
    NSUInteger end = [endPosition position];
    range.location = start;
    range.length = end - start;
    return range;
}

@end
