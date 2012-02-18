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

    attributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString(attributedString, CFRangeMake(0, 0), CFSTR(""));
    
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
    
    // Create the syntax highlighter
    syntaxHighlighter = [[GNSyntaxHighlighter alloc] initWithDelegate:self];
    [self addSubview:syntaxHighlighter];
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
    [self textChangedWithHighlight:NO];
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
    
    if(([shownText length] > 0) && 
       (indexIntoString > 0) && 
       ((char)[shownText characterAtIndex:indexIntoString - 1] == '\n'))
    {
        if(CTLineGetStringRange(closestLineVerticallyToPoint).location != indexIntoString)
        {
            // In this case, they've clicked at the very end of the line
            indexIntoString--;
        }
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
        
        // We need to compute the origin of this line in UIKit/Core Animation space.
        
        // Subtract the CG y coordinate of this line from our frame to get the bottom of the line
        
        CGFloat currentLineOriginY = [self frame].size.height - currentLineOriginCGCoords.y;
        
        // Next, subtract the ascent and descent (the height) for this font to obtain the origin in UIKit/CA space
        
        CGFloat lineHeight = CTFontGetAscent(defaultFont) + CTFontGetDescent(defaultFont);
        currentLineOriginY -= lineHeight;
        
        if(currentLineOriginY < 0)
        {
            currentLineOriginY = 0;
        }
        
        // If the line doesn't represent the range, skip it
        CFRange lineStringRange = CTLineGetStringRange(currentLine);
        NSUInteger lineRangeStart = lineStringRange.location;
        NSUInteger lineRangeEnd = lineStringRange.location = lineStringRange.length;
        if((lineRangeStart > rangeEnd) || (lineRangeEnd - 1 > rangeEnd) || (lineRangeEnd < rangeStart))
        {
            continue;
        }
                
        // If the point is greater than the currentLineOrigin.y, it could be our line!
        if(point.y >= currentLineOriginY)
        {
            closestLineVerticallyToPoint = currentLine;
            // If this is the last line, then it has to be it
            if(i == CFArrayGetCount(lines) - 1)
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
    NSString* beforeCaret = [shownText substringToIndex:textCaretIndex];
    NSString* afterCaret = [shownText substringFromIndex:textCaretIndex];
    
    shownText = [beforeCaret stringByAppendingString:text];
    shownText = [shownText stringByAppendingString:afterCaret];
    
    textCaretIndex++;
    
    [self textChangedWithHighlight:NO];
}

-(void)deleteBackward
{
    NSString* beforeCaret = [shownText substringToIndex:textCaretIndex];
    NSString* afterCaret = [shownText substringFromIndex:textCaretIndex];

    if ([beforeCaret length] > 0) {
        beforeCaret = [beforeCaret substringToIndex:[beforeCaret length] - 1];
        
        shownText = [beforeCaret stringByAppendingString:afterCaret];
        
        textCaretIndex--;
                
        [self textChangedWithHighlight:NO];
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
    
    // If shownText is empty, return the first location
    if([shownText length] == 0)
    {
        return CGRectMake(0, 0, kGNTextCaretViewWidth, fontSizeForText);
    }
    
    // TODO: The default font should be read from something like NSUserDefaults
    
    // First, find what line the character at this index is in
    
    CTLineRef lineAtCaret = [self lineForCharacterAtIndex:index];
    
    // If there is no line at the caret, return the first location
    
    if(lineAtCaret == NULL)
    {
        return CGRectMake(0, 0, kGNTextCaretViewWidth, fontSizeForText);
    }
    
    // Now, get the runs out of the line

    CTRunRef runForCaret = [self runForLine:lineAtCaret andCharacterAtIndex:index];
    
    CFRange caretRunStringRange = CTRunGetStringRange(runForCaret);
    
    NSUInteger indexOfGlyph = index - caretRunStringRange.location;
    
    CGFloat glyphOffset;
    
    // Get the origin of lineAtCaret

    CGPoint lineOrigin = [self originForLine:lineAtCaret];
    
    if(caretRunStringRange.location + caretRunStringRange.length == [shownText length])
    {
        glyphOffset = [self absoluteXPositionOfGlyphAtIndex:indexOfGlyph - 1
                                                      inRun:runForCaret
                                                 withinLine:lineAtCaret];
    }
    else
    {
        glyphOffset = [self absoluteXPositionOfGlyphAtIndex:indexOfGlyph 
                                                      inRun:runForCaret
                                                 withinLine:lineAtCaret];
    }
    
    return CGRectMake(glyphOffset,
                      [self frame].size.height - lineOrigin.y - fontSizeForText,
                      kGNTextCaretViewWidth,
                      fontSizeForText);
}

-(CTLineRef)lineForCharacterAtIndex:(NSUInteger)index
{
    CFArrayRef lines = CTFrameGetLines(frame);    
    NSUInteger indexLine = NSUIntegerMax;
    
    // If there are zero lines in the frame, then this is an empty file.
    // Return NULL.
    
    if(CFArrayGetCount(lines) == 0)
    {
        return NULL;
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
    
    // If we still couldn't find it, return NULL and log this.
    
    if(indexLine == NSUIntegerMax)
    {
        NSLog(@"Problem finding rect for character at index %u", index);
        return NULL;
    }
    
    return CFArrayGetValueAtIndex(lines, indexLine);
}

-(CTRunRef)runForLine:(CTLineRef)line andCharacterAtIndex:(NSUInteger)index
{
    // Get the runs out of the line
    
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    
    // If there aren't any runs, return NULL
    
    if(CFArrayGetCount(runs) == 0)
    {
        NSLog(@"Could not obtain line runs for character at index %u", index);
        return NULL;
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
    
    // If we couldn't find the run for the character, log it and return NULL
    
    if(runForCaretIndex == NSUIntegerMax)
    {
        NSLog(@"Could not find line run for character at index %u", index);
        return NULL;
    }
    
    CTRunRef runForCaret = CFArrayGetValueAtIndex(CTLineGetGlyphRuns(line), runForCaretIndex);
    
    return runForCaret;
}

-(CGPoint)originForLine:(CTLineRef)line
{
    NSUInteger numberOfLines = CFArrayGetCount(CTFrameGetLines(frame));
    
    // Get the origin of lineAtCaret
    
    CGPoint* lineOriginsForFrame = calloc(numberOfLines, sizeof(CGPoint));
    
    CTFrameGetLineOrigins(frame, CFRangeMake(0,0), lineOriginsForFrame);
    
    CGPoint lineOrigin;
    
    lineOrigin = lineOriginsForFrame[[self indexOfFrameLine:line]];
    
    free(lineOriginsForFrame);
    
    return lineOrigin;
}

-(NSUInteger)indexOfFrameLine:(CTLineRef)line
{
    // Grab the lines out of the frame
    CFArrayRef lines = CTFrameGetLines(frame);
    for(NSUInteger i = 0; i < CFArrayGetCount(lines); i++)
    {
        CTLineRef currentLine = CFArrayGetValueAtIndex(lines, i);
        
        if(CFEqual(line, currentLine))
        {
            return i;
        }
    }
    
    // If we didn't find it, return NSUIntegerMax
    
    return NSUIntegerMax;
}

-(CGFloat)absoluteXPositionOfGlyphAtIndex:(NSUInteger)index inRun:(CTRunRef)run withinLine:(CTLineRef)line
{        
    return CTRunGetPositionsPtr(run)[index-1].x + CTRunGetAdvancesPtr(run)[index-1].width;
}

-(void)textChangedWithHighlight:(BOOL)highlight
{    
    if(!highlight)
    {
        [syntaxHighlighter highlightText:[self shownText]];
    }
    
    [self setNeedsDisplay];
    [self fitFrameToText];
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

#pragma mark GNSyntaxHighlighterDelegate mathods

-(void)didHighlightText:(NSAttributedString*)highlightedText
{
    if(![[highlightedText string] isEqualToString:[(__bridge NSAttributedString*)attributedString string]])
    {
        if(attributedString)
        {
            CFRelease(attributedString);
        }
        
        NSMutableAttributedString* mutableHighlightedText = [[NSMutableAttributedString alloc] initWithAttributedString:highlightedText];
        
        attributedString = (__bridge CFMutableAttributedStringRef)mutableHighlightedText;
        CFRetain(attributedString);
        [self textChangedWithHighlight:YES];
    }
}

@end
