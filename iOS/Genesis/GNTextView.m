//
//  PHTextView.m
//  TextViewTester
//
//  Created by Peter Hajas on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GNTextView.h"

@implementation GNTextView

-(void)awakeFromNib
{
    innerView = [[GNTextInnerView alloc] initWithFrame:[self frame]];
    [innerView setContainerDelegate:self];
    
    [self addSubview:innerView];
    
    [innerView fitFrameToText];
    CGSize sizeForTextview = [innerView frame].size;
    
    [self setContentSize:sizeForTextview];
}

-(void)requiresSize:(CGSize)size
{
    [self setContentSize:size];
}

-(BOOL)resignFirstResponder
{
    [innerView resignFirstResponder];
    return [super resignFirstResponder];
}

-(void)requireSize:(CGSize)size
{
    [self setContentSize:size];
    NSLog(@"scrollview content height: %f", size.height);
}

#pragma mark Text Handling

-(void)setText:(NSString*)text
{
    [innerView setShownText:text];
}

-(NSString*)text
{
    return [innerView shownText];
}

@end
