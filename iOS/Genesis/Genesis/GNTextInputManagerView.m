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

#import "GNTextInputManagerView.h"
#import "GNTextGeometry.h"
#import "GNLineNumberTableView.h"
#import "GNTextAlternateInputView.h"
#import "GNFileRepresentation.h"
#import "GNTextRange.h"

@implementation GNTextInputManagerView

@synthesize delegate;
@synthesize inputView;
@synthesize inputAccessoryView;

@synthesize inputDelegate;

-(id)initWithFileRepresentation:(GNFileRepresentation*)representation
{
    self = [super init];
    if(self)
    {
        fileRepresentation = representation;
        
        // Subscribe to text changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textWillChange:)
                                                     name:GNTextWillChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidChange:)
                                                     name:GNTextDidChangeNotification
                                                   object:nil];
        
        // Subscribe to selection changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(selectionWillChange:)
                                                     name:GNSelectionWillChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(selectionDidChange:)
                                                     name:GNSelectionDidChangeNotification
                                                   object:nil];
        
        // Subscribe to keyboard command changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dismissKeyboard)
                                                     name:GNDismissKeyboardNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(switchToAutocompleteKeyboard)
                                                     name:GNSwitchToAutoCompleteKeyboardNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(switchToSystemKeyboard)
                                                     name:GNSwitchToSystemKeyboardNotification
                                                   object:nil];
        
        // (hacky) Subscribe to replacement notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(replaceCurrentWord:)
                                                     name:GNReplaceCurrentWordNotification
                                                   object:nil];
        
        // Subscribe to keyboard hide notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dismissKeyboard)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        
        caretView = [[GNTextCaretView alloc] init];
        [self addSubview:caretView];
        
        // Set our autoresizing mask
        [self setAutoresizingMask:(UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleHeight)];
        
        // Set our input accessory view
        inputAccessoryView = [[GNTextInputAccessoryView alloc] init];
        [self setInputAccessoryView:inputAccessoryView];
    }
    return self;
}

-(CGRect)caretRectForIndex:(NSUInteger)index
{
    NSUInteger line = [[fileRepresentation fileText] lineIndexForStringIndex:index];
    NSUInteger indexInLine = [[fileRepresentation fileText] indexInLineForAbsoluteStringIndex:index];
    
    indexInLine+=line;
    
    CGFloat lineHeight = [GNTextGeometry lineHeight];
    
    NSString* lineToIndex = [[fileRepresentation fileText] lineAtIndex:line toIndexInLine:indexInLine];
    CGSize sizeOfLineToIndex = [lineToIndex sizeWithFont:[GNTextGeometry font]];
    
    CGFloat xLocation = sizeOfLineToIndex.width + kGNLineNumberTableViewWidth;
    
    return CGRectMake(xLocation,
                      lineHeight * line,
                      kGNTextCaretViewWidth,
                      lineHeight);
}

-(void)textWillChange:(NSNotification*)notification
{
    [[self inputDelegate] textWillChange:self];
}

-(void)textDidChange:(NSNotification*)notification
{
    [[self inputDelegate] textDidChange:self];
}

-(void)selectionWillChange:(NSNotification*)notification
{
    [[self inputDelegate] selectionWillChange:self];
}

-(void)selectionDidChange:(NSNotification*)notification
{
    [[self inputDelegate] selectionDidChange:self];
    NSUInteger insertionIndexInLine = [[fileRepresentation insertionPointManager] insertionIndexInLine];
    
    CGRect newFrameForCaret = [self caretRectForIndex:[[fileRepresentation insertionPointManager] insertionIndex]];
    
    if(insertionIndexInLine == 0)
    {
        [caretView setHorizontalOffset:0.0];
    }
    
    [caretView setFrame:newFrameForCaret];
        
    [self becomeFirstResponder];
    [self toggleMinimalView:YES];
}

-(void)didScrollToVerticalOffset:(CGFloat)offset
{
    [caretView setVerticalOffset:offset];
}

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
    return [[fileRepresentation fileText] hasText];
}

-(void)insertText:(NSString *)text
{
    [[fileRepresentation fileText] insertText:text];
}

-(void)deleteBackward
{
    [[fileRepresentation fileText] deleteBackwards];
}

-(void)toggleMinimalView:(BOOL)toggle
{
    // Show the status bar and navigation bar
    [[UIApplication sharedApplication] setStatusBarHidden:toggle withAnimation:UIStatusBarAnimationSlide];
    [[NSNotificationCenter defaultCenter] postNotificationName:GNToggleNavigationBarNotification
                                                        object:[NSNumber numberWithBool:toggle]];
}

-(void)replaceCurrentWord:(id)object
{
    NSString* toReplace = [object object];
    [self replaceTextInRange:[[fileRepresentation fileText] rangeOfCurrentWord] withText:toReplace];
}

#pragma mark UITextInput methods

// Replacing and Returning Text

-(NSString*)textInRange:(GNTextRange*)range
{
    return [[fileRepresentation fileText] textInRange:[range rangeEquivalent]];
}

-(void)replaceRange:(GNTextRange*)range withText:(NSString *)text
{
    [[fileRepresentation fileText] replaceTextInRange:[range rangeEquivalent]
                                             withText:text];
}

// Working with Marked and Selected Text

-(GNTextRange*)selectedTextRange
{
    return [[GNTextRange alloc] initWithStartIndex:[[fileRepresentation insertionPointManager] insertionIndex]
                                          endIndex:[[fileRepresentation insertionPointManager] insertionIndex]];
}

-(void)setSelectedTextRange:(UITextRange*)selectedTextRange
{
    
}

-(GNTextRange*)markedTextRange
{
    return nil;
}

-(NSDictionary*)markedTextStyle
{
    return nil;
}

-(void)setMarkedTextStyle:(NSDictionary*)markedTextStyle
{
    
}

-(void)setMarkedText:(NSString*)markedText selectedRange:(NSRange)selectedRange
{
    
}

-(void)unmarkText
{
    
}

-(UITextStorageDirection)selectionAffinity
{
    return UITextStorageDirectionForward;
}

// Computing Text Ranges and Text Positions

-(GNTextRange*)textRangeFromPosition:(GNTextPosition*)fromPosition toPosition:(GNTextPosition*)toPosition
{
    return [[GNTextRange alloc] initWithStartPosition:fromPosition
                                          endPosition:toPosition];
}

-(GNTextPosition*)positionFromPosition:(GNTextPosition*)position offset:(NSInteger)offset
{
    return [[GNTextPosition alloc] initWithIndex:[position index] + offset];
}

-(GNTextPosition*)positionFromPosition:(GNTextPosition*)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    return (GNTextPosition*)[self positionFromPosition:position
                                                offset:offset];
}

-(GNTextPosition*)beginningOfDocument
{
    return [[GNTextPosition alloc] initWithIndex:0];
}

-(GNTextPosition*)endOfDocument
{
    return [[GNTextPosition alloc] initWithIndex:[[fileRepresentation fileText] textLength]];
}

// Evaluating Text Positions

-(NSComparisonResult)comparePosition:(GNTextPosition*)position toPosition:(GNTextPosition*)other
{
    NSInteger difference = [position index] - [other index];
    if(difference > 0)
    {
        return NSOrderedAscending;
    }
    if(difference < 0)
    {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}

-(NSInteger)offsetFromPosition:(GNTextPosition*)from toPosition:(GNTextPosition*)toPosition
{
    return [toPosition index] - [from index];
}

// Determining Layout and Writing Direction

-(GNTextPosition*)positionWithinRange:(GNTextRange*)range farthestInDirection:(UITextLayoutDirection)direction
{
    // If it's up or down, return the beginning/end of the range respectively
    if(direction == UITextLayoutDirectionUp)
    {
        return (GNTextPosition*)[range start];
    }
    else if(direction == UITextLayoutDirectionDown)
    {
        return (GNTextPosition*)[range end];
    }
    
    NSInteger rangeStart = [(GNTextPosition*)[range start] index];
    NSInteger rangeEnd = [(GNTextPosition*)[range end] index];
    
    // If it's left, return the position for the beginning of the line at rangeStart
    if(direction == UITextLayoutDirectionLeft)
    {
        NSRange rangeOfLine = [[fileRepresentation fileText] rangeOfLineAtStringIndex:rangeStart];
        return [[GNTextPosition alloc] initWithIndex:rangeOfLine.location];
    }
    // If it's right, return the position for the end of the line at rangeEnd
    else if(direction == UITextLayoutDirectionRight)
    {
        NSRange rangeOfLine = [[fileRepresentation fileText] rangeOfLineAtStringIndex:rangeEnd];
        return [[GNTextPosition alloc] initWithIndex:rangeOfLine.location + rangeOfLine.length];
    }
    
    NSLog(@"Couldn't find position within range %@ farthest in direction %d", range, direction);
    return [[GNTextPosition alloc] initWithIndex:0];
}

-(GNTextRange*)characterRangeByExtendingPosition:(GNTextPosition*)position inDirection:(UITextLayoutDirection)direction
{
    GNTextPosition* startPosition = [[GNTextPosition alloc] initWithIndex:0];
    GNTextPosition* endPosition = [[GNTextPosition alloc] initWithIndex:0];
    
    // If it's up, then the start is the beginning of the document, and the end is position
    if(direction == UITextLayoutDirectionUp)
    {
        startPosition = (GNTextPosition*)[self beginningOfDocument];
        endPosition = position;
    }
    
    // If it's down, then the start is position, and the end is the end of the document
    if(direction == UITextLayoutDirectionDown)
    {
        startPosition = position;
        endPosition = (GNTextPosition*)[self endOfDocument];
    }
    
    // If it's left or right, we care about the range of the line at position
    NSRange rangeOfLine = [[fileRepresentation fileText] rangeOfLineAtStringIndex:[position index]];
    
    // If it's left, then the start is the beginning of the line at position, and the end is position
    if(direction == UITextLayoutDirectionLeft)
    {
        startPosition = [[GNTextPosition alloc] initWithIndex:rangeOfLine.location];
        endPosition = position;
    }
    
    // If it's right, then the start is position, and the end is the end of the line at position
    if(direction == UITextLayoutDirectionRight)
    {
        startPosition = position;
        endPosition = [[GNTextPosition alloc] initWithIndex:rangeOfLine.location + rangeOfLine.length];
    }
    
    return [[GNTextRange alloc] initWithStartPosition:startPosition
                                          endPosition:endPosition];
}

-(UITextWritingDirection)baseWritingDirectionForPosition:(GNTextPosition*)position inDirection:(UITextStorageDirection)direction
{
    return UITextWritingDirectionLeftToRight;
}

-(void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange*)range
{
    
}

// Geometry and Hit-Testing Methods

-(CGRect)firstRectForRange:(GNTextRange*)range
{
    // Hackity-hack, don't talk back
    return CGRectMake(0, 0, 100, 100);
}

-(CGRect)caretRectForPosition:(GNTextPosition*)position
{
    CGRect uncomputedCaretRect = [self caretRectForIndex:[position index]];
    CGRect computedCaretRect = [caretView calculatedFrameForFrame:uncomputedCaretRect];
    return computedCaretRect;
}

-(GNTextPosition*)closestPositionToPoint:(CGPoint)point
{
    return (GNTextPosition*)[self closestPositionToPoint:point
                                             withinRange:[[GNTextRange alloc] initWithStartPosition:(GNTextPosition*)[self beginningOfDocument]
                                                                                        endPosition:(GNTextPosition*)[self endOfDocument]]];
}

-(GNTextPosition*)closestPositionToPoint:(CGPoint)point withinRange:(GNTextRange*)range
{
    // Currently ignore range.
    
    // Get the table view cell for this point
    GNTextTableViewCell* cellAtPoint = [delegate cellAtPoint:point];
    
    NSUInteger indexAtPoint = [cellAtPoint stringIndexAtPoint:point];
    
    return [[GNTextPosition alloc] initWithIndex:indexAtPoint];
}

-(GNTextRange*)characterRangeAtPoint:(CGPoint)point
{
    GNTextPosition* closestPositionToPoint = (GNTextPosition*)[self closestPositionToPoint:point];
    return [[GNTextRange alloc] initWithStartPosition:closestPositionToPoint
                                          endPosition:closestPositionToPoint];
}

// Text Input Delegate and Text Input Tokenizer

-(id<UITextInputTokenizer>)tokenizer
{
    return [[UITextInputStringTokenizer alloc] init];
}

#pragma mark UIResponder methods

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(BOOL)becomeFirstResponder
{
    [caretView setHidden:NO];
    [caretView blink];
    return [super becomeFirstResponder];
}

-(void)dismissKeyboard
{
    [self resignFirstResponder];
    [self toggleMinimalView:NO];
    [caretView setHidden:YES];
}

-(void)switchToAutocompleteKeyboard;
{
    alternateInputView = [[GNTextAutocompleteInputView alloc] initWithDelegate:self
                                                         andFileRepresentation:fileRepresentation];
    [self resignFirstResponder];
    [self setInputView:alternateInputView];
    [self becomeFirstResponder];
}

-(void)switchToSystemKeyboard
{
    alternateInputView = nil;
    [self resignFirstResponder];
    [self setInputView:nil];
    [self becomeFirstResponder];
}

#pragma mark GNTextAlternateInputViewDelegate methods

-(void)insertText:(NSString*)text indexDelta:(NSInteger)indexDelta
{
    [[fileRepresentation fileText] insertText:text indexDelta:indexDelta];
}

-(void)replaceTextInRange:(NSRange)range withText:(NSString*)text
{
    [[fileRepresentation fileText] replaceTextInRange:range withText:text];
}

#pragma mark Lifecycle cleanup methods

-(void)cleanUp
{
    [caretView cleanUp];
    [caretView removeFromSuperview];
    alternateInputView = nil;
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
