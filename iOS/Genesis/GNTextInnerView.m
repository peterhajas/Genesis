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

#import "GNTextInnerView.h"

#define DEFAULT_FONT_FAMILY @"Courier"
#define DEFAULT_SIZE 16

static CTFontRef defaultFont = nil;

@implementation GNTextInnerView

@synthesize containerDelegate;

-(void)buildUpView
{
    shownText = [[NSString alloc] initWithString:@""];

    attributedString = NULL;
    frameSetter = NULL;
    [self evaluateFramesetter];
    
    // Initialize our input tokenizer (using the base UIKit class)
    stringTokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
    
    // Create our caret view
    caretView = [[GNTextCaretView alloc] initWithFrame:CGRectMake(0, 0, 5, 10)];
    [self addSubview:caretView];
    
    // Our caret index
    textCaretIndex = 0;
    
    // Gesture recognizer for moving the cursor
    tapGestureReognizer = [[UITapGestureRecognizer alloc] initWithTarget:self 
                                                                  action:@selector(tapInView:)];
    [self addGestureRecognizer:tapGestureReognizer];
}

-(id)initWithFrame:(CGRect)frame_
{
    self = [super initWithFrame:frame_];
    if(self)
    {
        [self buildUpView];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self buildUpView];
    }
    return self;
}

#pragma mark Handling shown text changes

-(void)setShownText:(NSString*)text
{
    shownText = text;
    [self setNeedsDisplay];
    [self fitFrameToText];
}

-(NSString*)shownText
{
    return shownText;
}

#pragma mark UITextInput methods

// Methods for manipulating text.
-(NSString*)textInRange:(UITextRange*)range
{
    NSRange stringRange = [(GNTextRange*)range textRangeRange];
    return [shownText substringWithRange:stringRange];
}
-(void)replaceRange:(UITextRange*)range withText:(NSString*)text
{
    NSRange stringRange = [(GNTextRange*)range textRangeRange];
    NSString* textToReplace = [shownText substringWithRange:stringRange];
    
    [shownText stringByReplacingOccurrencesOfString:textToReplace withString:text options:0 range:stringRange];
}

-(void)setMarkedText:(NSString*)markedText selectedRange:(NSRange)selectedRange
{
    //no-op for now
}  // selectedRange is a range within the markedText
-(void)unmarkText
{
    
}

// Methods for creating ranges and positions.
-(UITextRange*)textRangeFromPosition:(UITextPosition*)fromPosition toPosition:(UITextPosition*)toPosition
{
    NSUInteger from = [(GNTextPosition*)fromPosition position];
    NSUInteger to = [(GNTextPosition*)toPosition position];
    
    return [[GNTextRange alloc] initWithStartPosition:from endPosition:to];
}
-(UITextPosition*)positionFromPosition:(UITextPosition*)position offset:(NSInteger)offset
{
    NSUInteger from = [(GNTextPosition*)position position];
    GNTextPosition* shiftedPosition = [[GNTextPosition alloc] init];
    shiftedPosition.position = from + offset;
    
    return shiftedPosition;
}
-(UITextPosition*)positionFromPosition:(UITextPosition*)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    // Same as above, we don't support other writing directions
    return [self positionFromPosition:position offset:offset];
}

// Simple evaluation of positions
-(NSComparisonResult)comparePosition:(UITextPosition*)position toPosition:(UITextPosition*)other
{
    NSUInteger from = [(GNTextPosition*)position position];
    NSUInteger to = [(GNTextPosition*)other position];
    
    NSInteger result = to - from;
    // If the result is positive, it's ascending
    if(result > 0)
    {
        return NSOrderedAscending;
    }
    // If the result is negative, it's descending
    else if(result < 0)
    {
        return NSOrderedDescending;
    }
    // If it's neither of these, then it's the same!
    return NSOrderedSame;
}
-(NSInteger)offsetFromPosition:(UITextPosition*)from toPosition:(UITextPosition*)toPosition
{
    NSUInteger fromIndexPosition = [(GNTextPosition*)from position];
    NSUInteger toIndexPosition = [(GNTextPosition*)toPosition position];
    
    return toIndexPosition - fromIndexPosition;
}

// Layout questions.
-(UITextPosition*)positionWithinRange:(UITextRange*)range farthestInDirection:(UITextLayoutDirection)direction
{
    GNTextPosition* startPosition = (GNTextPosition*)[(GNTextRange*)range start];
    GNTextPosition* endPosition = (GNTextPosition*)[(GNTextRange*)range end];
    
    // If the layout direction is left or top, return the start position
    if((direction == UITextLayoutDirectionLeft) || (direction == UITextLayoutDirectionDown))
    {
        return startPosition;
    }
    
    // If not, return the end position
    
    return endPosition;
}

-(UITextRange*)characterRangeByExtendingPosition:(UITextPosition*)position inDirection:(UITextLayoutDirection)direction
{
    // If the layout direction is left or top, return to the start of the string
    if((direction == UITextLayoutDirectionLeft) || (direction == UITextLayoutDirectionDown))
    {
        return [[GNTextRange alloc] initWithStartPosition:0
                                              endPosition:[(GNTextPosition*)position position]];
    }
    
    // If not, return from the position to the end of the string
    
    return [[GNTextRange alloc] initWithStartPosition:[(GNTextPosition*)position position]
                                          endPosition:[shownText length] - 1];
    
}

// Writing direction
-(UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition*)position inDirection:(UITextStorageDirection)direction
{
    return UITextWritingDirectionLeftToRight;
}
-(void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange*)range
{
    //no-op for now
}

// Geometry used to provide, for example, a correction rect.
-(CGRect)firstRectForRange:(UITextRange*)range
{
    return CGRectMake(0, 0, 0, 0);
}
-(CGRect)caretRectForPosition:(UITextPosition*)position
{
    CGRect characterRect = [self rectForCharacterAtIndex:[(GNTextPosition*)position position]];
    characterRect.size = CGSizeMake(5, characterRect.size.height);
    return characterRect;
}

// Hit testing.
-(UITextPosition*)closestPositionToPoint:(CGPoint)point
{
    return [self closestPositionToPoint:point withinRange:[[GNTextRange alloc] initWithStartPosition:0 endPosition:[shownText length] - 1]];
}
-(UITextPosition*)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange*)range
{    
    CTLineRef closestLineVerticallyToPoint = [self closestLineToPoint:point inRange:(GNTextRange*)range];
    
    // Now that we have the closest line vertically, find the index for the point
    CFIndex indexIntoString = CTLineGetStringIndexForPosition(closestLineVerticallyToPoint, point);
    if((indexIntoString > 0) && ((char)[shownText characterAtIndex:indexIntoString-1] == '\n'))
    {
        // Special case when the cursor is caught between two lines!
        indexIntoString--;
    }
    GNTextPosition* closestPosition = [[GNTextPosition alloc] init];
    if (indexIntoString < 0)
        [closestPosition setPosition:0];
    else
        [closestPosition setPosition:indexIntoString];
        
    return closestPosition;
}
-(UITextRange*)characterRangeAtPoint:(CGPoint)point
{
    CTLineRef closestLineVerticallyToPoint = [self closestLineToPoint:point inRange:[[GNTextRange alloc] initWithStartPosition:0 endPosition:[shownText length]]];

    // Now that we have the closest line vertically, find the index for the point
    CFIndex indexIntoString = CTLineGetStringIndexForPosition(closestLineVerticallyToPoint, point);
    GNTextRange* characterRangeAtPoint = [[GNTextRange alloc] initWithStartPosition:indexIntoString endPosition:indexIntoString+1];
    
    return characterRangeAtPoint;
}

-(CTLineRef)closestLineToPoint:(CGPoint)point inRange:(GNTextRange*)range
{
    CFArrayRef lines = CTFrameGetLines(frame);
    CGPoint lineOrigins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
    
    NSRange characterRange = [(GNTextRange*)range textRangeRange];
    NSUInteger rangeStart = characterRange.location;
    NSUInteger rangeEnd = characterRange.location = characterRange.length;
    
    CTLineRef closestLineVerticallyToPoint = NULL;
    
    // If there are no lines, return NULL
    if(CFArrayGetCount(lines) < 1)
    {
        return NULL;
    }
    
    // Loop through the lines in our frame
    for(NSUInteger i = 0; i < CFArrayGetCount(lines); i++)
    {
        CTLineRef currentLine = CFArrayGetValueAtIndex(lines, i);
        CGPoint currentLineOriginCGCoords = lineOrigins[i];
        CGPoint currentLineOrigin = CGPointMake(currentLineOriginCGCoords.x, [self frame].size.height - currentLineOriginCGCoords.y);
        
        // We need to compute the origin of this line in UIKit/Core Animation space.
        
        // Grab the runs for this line
        CFArrayRef runsForCurrentLine = CTLineGetGlyphRuns(currentLine);
        if(CFArrayGetCount(runsForCurrentLine) < 1)
        {
            NSLog(@"Problem finding runs for line");
            return NULL;
        }
        
        // Because this font is monospaced, and we're never modifying its size, we can
        // just grab the first run we find.
        
        CTRunRef runForCurrentLine = CFArrayGetValueAtIndex(runsForCurrentLine, 0);
        
        // Using the image bounds for this run, grab its height, and subtract that from
        // the origin for this line
        
        CGRect runFrame = CTRunGetImageBounds(runForCurrentLine, staleContext, CFRangeMake(0, 0));
        
        currentLineOrigin.y-=runFrame.size.height;
        
        // If the line doesn't  represent the range, skip it
        CFRange lineStringRange = CTLineGetStringRange(currentLine);
        NSUInteger lineRangeStart = lineStringRange.location;
        NSUInteger lineRangeEnd = lineStringRange.location = lineStringRange.length;
        if((lineRangeStart > rangeEnd) || (lineRangeEnd - 1 > rangeEnd) || (lineRangeEnd < rangeStart))
        {
            continue;
        }
        
        // Fine the closest line that doesn't go past point
        if(currentLineOrigin.y < point.y)
        {
            closestLineVerticallyToPoint = currentLine;
        }
        else
        {
            if(closestLineVerticallyToPoint !=NULL)
            {
                break;
            }
        }
    }
    
    CFRetain(closestLineVerticallyToPoint);
    
    return closestLineVerticallyToPoint;
}

-(UITextPosition*)beginningOfDocument
{
    GNTextPosition* beginning = [[GNTextPosition alloc] init];
    [beginning setPosition:0];
    return beginning;
}

-(UITextPosition*)endOfDocument
{
    GNTextPosition* end = [[GNTextPosition alloc] init];
    [end setPosition:[shownText length]];
    return end;
}

-(id<UITextInputDelegate>)inputDelegate
{
    return textInputDelegate;
}

-(void)setInputDelegate:(id<UITextInputDelegate>)inputDelegate
{
    textInputDelegate = inputDelegate;
}

-(UITextRange*)markedTextRange
{
    return nil;
}

-(NSDictionary*)markedTextStyle
{
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[UIColor whiteColor],
                                                                         [UIColor blackColor],
                                                                         [UIFont fontWithName:DEFAULT_FONT_FAMILY
                                                                                         size:8.0],
                                                                          nil] 
                                       forKeys:[NSArray arrayWithObjects:UITextInputTextBackgroundColorKey,
                                                                         UITextInputTextColorKey,
                                                                         UITextInputTextFontKey,
                                                                         nil]];
}

-(void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
    
}

-(UITextRange*)selectedTextRange
{
    return nil;
}

-(void)setSelectionAffinity:(UITextStorageDirection)selectionAffinity
{
    // no-op for now
}

-(UITextStorageDirection)selectionAffinity
{
    return UITextStorageDirectionForward;
}

-(UIView*)textInputView
{
    return self;
}

-(id<UITextInputTokenizer>)tokenizer
{
    return stringTokenizer;
}




// optional
/*
-(NSDictionary*)textStylingAtPosition:(UITextPosition*)position inDirection:(UITextStorageDirection)direction
{

}
-(UITextPosition*)positionWithinRange:(UITextRange*)range atCharacterOffset:(NSInteger)offset
{

}
-(NSInteger)characterOffsetOfPosition:(UITextPosition*)position withinRange:(UITextRange*)range
{

}
 */

#pragma mark UITextInputTraits methods

-(UITextAutocapitalizationType)autocapitalizationType
{
    return UITextAutocapitalizationTypeNone;
}

-(UITextAutocorrectionType)autocorrectionType
{
    return UITextAutocorrectionTypeNo;
}

-(BOOL)enablesReturnKeyAutomatically
{
    return YES;
}

-(UIKeyboardAppearance)keyboardAppearance
{
    return UIKeyboardAppearanceDefault;
}

-(UIKeyboardType)keyboardType
{
    return UIKeyboardTypeDefault;
}

-(UIReturnKeyType)returnKeyType
{
    return UIReturnKeyDefault;
}

-(BOOL)isSecureTextEntry
{
    return NO;
}

#pragma mark UIKeyInput methods

-(BOOL)hasText
{
    return [shownText length] > 0;
}

-(void)insertText:(NSString *)text
{
    NSLog(@"insert text");
    NSString* beforeCaret = [shownText substringToIndex:textCaretIndex];
    NSString* afterCaret = [shownText substringFromIndex:textCaretIndex];
    
    shownText = [beforeCaret stringByAppendingString:text];
    shownText = [shownText stringByAppendingString:afterCaret];
    
    textCaretIndex++;
    
    [self setNeedsDisplay];
    [self fitFrameToText];
}

-(void)deleteBackward
{
    NSString* beforeCaret = [shownText substringToIndex:textCaretIndex];
    NSString* afterCaret = [shownText substringFromIndex:textCaretIndex];

    if ([beforeCaret length] > 0) {
        beforeCaret = [beforeCaret substringToIndex:[beforeCaret length] - 1];
        
        shownText = [beforeCaret stringByAppendingString:afterCaret];
        
        textCaretIndex--;
                
        [self setNeedsDisplay];
        [self fitFrameToText];
    }
}

#pragma mark User Interaction
-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)tapInView:(id)sender
{
    CGPoint tapLocation = [sender locationInView:self];
    GNTextPosition* closestPositionToPoint = (GNTextPosition*)[self closestPositionToPoint:tapLocation];
    
    [self moveCaretToIndex:[closestPositionToPoint position]];
    [self becomeFirstResponder];
}

#pragma mark View drawing and sizing

-(void)moveCaretToIndex:(NSUInteger)index
{
    NSLog(@"move caret");
    textCaretIndex = index;
    
    CGRect characterRect = [self rectForCharacterAtIndex:index];
    [caretView setFrame:characterRect];
}

-(void)redrawText
{    
    [self evaluateFramesetter];
    [self plotText];
}

-(void)evaluateFramesetter
{
    CFStringRef foundationString = (__bridge CFStringRef)shownText;
    
    if(attributedString != NULL)
    {
        CFRelease(attributedString);
        attributedString = NULL;
    }
    
    attributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    
    // If we have text already, fill in the attributed string with the value of shownText
    if (CFStringGetLength(foundationString) > 0)
        CFAttributedStringReplaceString(attributedString, CFRangeMake(0, 0), foundationString);
    
    // What font do we want?
    defaultFont = CTFontCreateWithName((CFStringRef)DEFAULT_FONT_FAMILY, DEFAULT_SIZE, NULL);
    
    CFAttributedStringSetAttribute(attributedString, 
                                   CFRangeMake(0, CFAttributedStringGetLength(attributedString)),
                                   kCTFontAttributeName, 
                                   defaultFont);
    
    // Create the framesetter with the attributed string.
    if(frameSetter != NULL)
    {
        CFRelease(frameSetter);
        frameSetter = NULL;
    }
    frameSetter = CTFramesetterCreateWithAttributedString(attributedString);
}

-(void)plotText
{
    // Initialize a graphics context and set the text matrix to a known value.
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    
    // Set background color to white
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, [self frame]);
    
    // Initialize a rectangular path.
    CGMutablePathRef path = CGPathCreateMutable();
    //CGRect bounds = CGRectMake(10.0, 10.0, 320.0, 300.0);
    CGPathAddRect(path, NULL, [self frame]);
    
    // Account for Cocoa coordinate system
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -[self frame].size.height);
    
    // Create the frame and draw it into the graphics context
    if(frame)
    {
        CFRelease(frame);
        frame = NULL;
    }
    
    frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, NULL);
    CTFrameDraw(frame, context);
    staleContext = context;
    CGContextRestoreGState(context);
    
    [self moveCaretToIndex:textCaretIndex];
    
    CFRelease(path);
}

-(CGRect)rectForCharacterAtIndex:(NSUInteger)index
{
    CTFontRef fontForText;
    CGFloat   fontSizeForText;
    
    // If we have no attributed string, we can't get the attributes!
    if (CFAttributedStringGetLength(attributedString) > 0)
    {
        fontForText = CFAttributedStringGetAttribute(attributedString, 0, kCTFontAttributeName, NULL);
        fontSizeForText = CTFontGetSize(fontForText);
    } 
    else
    {
        // ... so just use the default font.
        fontForText = defaultFont;
        fontSizeForText = DEFAULT_SIZE;
    }
    
    // TODO: The default font should be read from something like NSUserDefaults
    
    // First, find what line the character at this index is in
    
    CFArrayRef lines = CTFrameGetLines(frame);    
    NSUInteger indexLine = NSUIntegerMax;
    
    // If there are zero lines in the frame, then this is an empty file.
    // Return a rect corresponding to the first index.
    
    if(CFArrayGetCount(lines) == 0)
    {
        return CGRectMake(0, 0, kGNTextCaretViewWidth, fontSizeForText);
    }
    
    // Loop through the lines in our frame
    for(NSUInteger i = 0; i < CFArrayGetCount(lines); i++)
    {
        // Find the line range that represents our index
        
        CTLineRef currentLine = CFArrayGetValueAtIndex(lines, i);
        CFRange lineStringRange = CTLineGetStringRange(currentLine);
        
        if((index >= lineStringRange.location) &&
           (index <= lineStringRange.location + lineStringRange.length))
        {
            // We found the right line!
            indexLine = i;
            break;
        }
    }
    
    if(indexLine == NSUIntegerMax)
    {
        NSLog(@"Problem finding rect for character at index %u", index);
        return CGRectMake(0, 0, 0, 0);
    }
    
    CTLineRef lineAtCaret = CFArrayGetValueAtIndex(lines, indexLine);
    
    // Now, get the runs out of the line

    CFArrayRef runs = CTLineGetGlyphRuns(lineAtCaret);
    
    if(CFArrayGetCount(runs) < 1)
    {
        NSLog(@"Could not obtain line runs for character at index %u", index);
        return CGRectMake(0, 0, 0, 0);
    }
    
    // Find the run this index belongs to
    
    NSUInteger runForCaretIndex = NSUIntegerMax;
    
    for(NSUInteger i = 0; i < CFArrayGetCount(runs); i++)
    {
        CTRunRef run = CFArrayGetValueAtIndex(runs, i);
        CFRange runRange = CTRunGetStringRange(run);
        
        if((index >= runRange.location) && (index <= runRange.location + runRange.length))
        {
            runForCaretIndex = i;
            break;
        }
    }
    
    if(runForCaretIndex == NSUIntegerMax)
    {
        NSLog(@"Could not find line run for character at index %u", index);
        return CGRectMake(0, 0, 0, 0);
    }

    CTRunRef runForCaret = CFArrayGetValueAtIndex(CTLineGetGlyphRuns(lineAtCaret), runForCaretIndex);
    CFRange caretRunStringRange = CTRunGetStringRange(runForCaret);
    
    NSUInteger indexOfGlyph = index - caretRunStringRange.location;
    
    CGPoint glyphPosition;
    
    if(caretRunStringRange.location + caretRunStringRange.length == [shownText length])
    {
        glyphPosition = CTRunGetPositionsPtr(runForCaret)[indexOfGlyph-1];
        if([shownText length] > 0)
        {
            double glyphWidth = CTRunGetTypographicBounds(runForCaret, CFRangeMake(0, 1), NULL, NULL, NULL);
            glyphPosition.x += glyphWidth;
        }
    }
    else
    {
        glyphPosition = CTRunGetPositionsPtr(runForCaret)[indexOfGlyph];
    }
    
    // Get the origin of lineAtCaret
    
    CGPoint* lineOriginsForFrame;
    
    lineOriginsForFrame = calloc(CFArrayGetCount(lines), sizeof(CGPoint));
        
    CTFrameGetLineOrigins(frame, CFRangeMake(0,0), lineOriginsForFrame);
    
    CGPoint lineOrigin;
    
    lineOrigin = lineOriginsForFrame[indexLine];
    
    free(lineOriginsForFrame);
    
    NSLog(@"rect for character at index: %u is (%f,%f) @ %fx%f", index, 
                                                                 glyphPosition.x,
                                                                 [self frame].size.height - lineOrigin.y - fontSizeForText,
                                                                 kGNTextCaretViewWidth,
                                                                 fontSizeForText);
    
    return CGRectMake(glyphPosition.x,
                      [self frame].size.height - lineOrigin.y - fontSizeForText,
                      kGNTextCaretViewWidth,
                      fontSizeForText);
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
        
    [self redrawText];
}

-(void)fitFrameToText
{    
    /*
     * This view doesn't need to ever be smaller than the GNTextView superview, does it?
     * If the string is empty, this routine fails for some reason.
     */
    return; // temporarily disabled
    
    // Find how large of a textarea we need
    CGSize sizeForText = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), NULL, CGSizeMake(CGFLOAT_MAX,CGFLOAT_MAX), NULL);
    
    [self setFrame:CGRectMake(0, 0, sizeForText.width,sizeForText.height)];
    
    NSLog(@"height for framesetter: %f", sizeForText.height);
    
    [containerDelegate requireSize:sizeForText];
}

@end
