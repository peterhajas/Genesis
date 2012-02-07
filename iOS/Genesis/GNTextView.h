//
//  PHTextView.h
//  TextViewTester
//
//  Created by Peter Hajas on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GNTextInnerView.h"

@interface GNTextView : UIScrollView <GNTextInnerViewContainerProtocol>

{
    GNTextInnerView* innerView;
}

@property(nonatomic,retain) NSString* text;

@end
