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

#import "GNTextAutocompleteInputView.h"

@implementation GNTextAutocompleteInputView

-(id)initWithDelegate:(NSObject<GNTextAlternateInputViewDelegate> *)alternateDelegate andFileRepresentation:(GNFileRepresentation *)representation
{
    self = [super initWithDelegate:alternateDelegate andFileRepresentation:representation];
    if(self)
    {
        // Initialize the tableview
        autocompleteSuggestions = [[UITableView alloc] initWithFrame:[self frame] style:UITableViewStylePlain];
        [autocompleteSuggestions setDelegate:self];
        [autocompleteSuggestions setDataSource:self];
        [autocompleteSuggestions setAutoresizingMask:[self autoresizingMask]];
        [self addSubview:autocompleteSuggestions];
        
        // Initialize the autocomplete suggestions array
        autocompleteSuggestionsForCurrentWord = [[NSArray alloc] init];
        
        [self textChanged:nil];
    }
    return self;
}

-(void)textChanged:(id)object
{
    autocompleteSuggestionsForCurrentWord = [[fileRepresentation autoCompleteDictionary] orderedMatchesForText:[fileRepresentation currentWord]];
    [autocompleteSuggestions reloadData];
}

#pragma mark UITableViewDelegate methods

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString* selectedSuggestion = [autocompleteSuggestionsForCurrentWord objectAtIndex:[indexPath row]];
    [delegate replaceTextInRange:[fileRepresentation rangeOfCurrentWord] withText:selectedSuggestion];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kGNSystemKeyboard" object:nil];
}

#pragma mark UITableViewDataSource methods

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:@"kGNAutoCompleteTableViewCellIdentifier"];
    [[cell textLabel] setText:[autocompleteSuggestionsForCurrentWord objectAtIndex:[indexPath row]]];
    return cell;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [autocompleteSuggestionsForCurrentWord count];
}

@end
