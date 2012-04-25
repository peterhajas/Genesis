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

#import "GNLoupeView.h"
#import "GNLineNumberTableView.h"

@implementation GNLoupeView

@synthesize delegate;

-(id)init
{
    self = [super initWithFrame:CGRectMake(0,
                                           0,
                                           2 * GNLoupeViewRadius,
                                           2 * GNLoupeViewRadius)];
    if(self)
    {
        // Register for loupe notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loupeShouldShow:)
                                                     name:GNLoupeShouldShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loupeShouldMove:)
                                                     name:GNLoupeShouldMoveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loupeShouldFinish:)
                                                     name:GNLoupeShouldFinishNotification
                                                   object:nil];
        
        // Add our image view
        textImageView = [[UIImageView alloc] initWithFrame:[self frame]];
        [self addSubview:textImageView];
        
        // Make our layer circular!
        CALayer* layer = [self layer];
        
        layer.masksToBounds = YES;
        [layer setBackgroundColor:[[UIColor purpleColor] CGColor]];
        [layer setCornerRadius:GNLoupeViewRadius];
        
        // Hide us
        [self setHidden:YES];
    }
    
    return self;
}

#pragma mark Loupe notifications

-(void)loupeShouldShow:(NSNotification*)notification
{
    // Get the scaled text image
    UIImage* textImage = [self scaledImage];
    
    CGPoint point = [self pointForNotification:notification];
    
    [textImageView setFrame:CGRectMake(point.x,
                                       point.y,
                                       [textImage size].width,
                                       [textImage size].height)];
    
    [textImageView setImage:textImage];
    
    // TODO: animate open
    [self setHidden:NO];
    
    [self setFrame:[self frameForTouchPoint:point]];
    [self shiftTextImageForPoint:point];
}

-(void)loupeShouldMove:(NSNotification*)notification
{
    CGPoint point = [self pointForNotification:notification];
    [self setFrame:[self frameForTouchPoint:point]];
    [self shiftTextImageForPoint:point];
}

-(void)loupeShouldFinish:(NSNotification*)notification
{
    CGPoint point = [self pointForNotification:notification];
    // TODO: animate away
    [self setHidden:YES];
    [self setFrame:[self frameForTouchPoint:point]];
    [self shiftTextImageForPoint:point];
}

-(CGPoint)pointForNotification:(NSNotification*)notification
{
    NSValue* value = [notification object];
    return [value CGPointValue];
}

-(UIImage*)scaledImage
{
    UIImage* image = [delegate imageForCurrentText];
    UIImage* scaledImage = [UIImage imageWithCGImage:[image CGImage]
                                               scale:0.75
                                         orientation:UIImageOrientationUp];
    return scaledImage;
}

#pragma mark Loupe geometry methods

-(CGRect)frameForTouchPoint:(CGPoint)point
{
    return CGRectMake(point.x - 0.5 * GNLoupeViewRadius,
                      point.y - + GNLoupeViewRadius,
                      2 * GNLoupeViewRadius,
                      2 * GNLoupeViewRadius);
}

-(void)shiftTextImageForPoint:(CGPoint)point
{
    [textImageView setFrame:CGRectMake(-1.0 * point.x,
                                       -1.0 * point.y,
                                       [textImageView frame].size.width,
                                       [textImageView frame].size.height)];
}

-(void)cleanUp
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
