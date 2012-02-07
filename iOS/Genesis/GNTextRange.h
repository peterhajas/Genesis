//
//  PHTextRange.h
//  TextViewTester
//
//  Created by Peter Hajas on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GNTextPosition : UITextPosition
{
    NSUInteger position;
}

@property(readwrite) NSUInteger position;

@end

@interface GNTextRange : UITextRange
{
    GNTextPosition* startPosition;
    GNTextPosition* endPosition;
}

-(id)initWithStartPosition:(NSUInteger)start endPosition:(NSUInteger)end;
-(NSRange)textRangeRange;

@end
