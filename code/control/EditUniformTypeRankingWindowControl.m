#import "EditUniformTypeRankingWindowControl.h"

#import "UniformTypeRanking.h"
#import "UniformType.h"


@interface TypeCell : NSObject {
  UniformType  *type;
  BOOL  isDominated;
}

- (id) initWithUniformType: (UniformType *)type;

- (UniformType *) uniformType;
- (BOOL) isDominated;
- (void) setDominated: (BOOL) flag;

@end


@interface EditUniformTypeRankingWindowControl (PrivateMethods)

- (void) fetchCurrentTypeList;
- (void) commitChangedTypeList;

- (void) closeWindow;

- (void) updateWindowState;
- (void) updateDominatedStatusInRange: (NSRange) range;

- (void) moveCellUpFromIndex: (int) index;
- (void) moveCellDownFromIndex: (int) index;

@end


@implementation EditUniformTypeRankingWindowControl

- (id) init {
  return [self initWithUniformTypeRanking:
                   [UniformTypeRanking defaultUniformTypeRanking]];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithUniformTypeRanking: (UniformTypeRanking *)typeRankingVal {
  if (self = [super initWithWindowNibName: @"EditUniformTypeRankingWindow" 
                      owner: self]) {
    typeRanking = [typeRankingVal retain];
    typeCells = [[NSMutableArray arrayWithCapacity: 
                    [[typeRanking rankedUniformTypes] count]] retain];
  }
  
  return self;
}

- (void) dealloc {
  [typeRanking release];
  [typeCells release];

  [super dealloc];
}


- (void) windowDidLoad {
  [typesBrowser setDelegate: self];
    
  // [self updateWindowState:nil];
}


- (IBAction) cancelAction: (id) sender {
  [self closeWindow];
}

- (IBAction) okAction: (id) sender {
  [self commitChangedTypeList];

  [self closeWindow];
}

- (IBAction) moveToTopAction: (id) sender {
  int  i = [typesBrowser selectedRowInColumn: 0];
  
  while (i > 0) {
    [self moveCellUpFromIndex: i];
    i--;
  }
  
  [typesBrowser validateVisibleColumns];
  [self updateWindowState];
}

- (IBAction) moveToBottomAction: (id) sender {
  int  i = [typesBrowser selectedRowInColumn: 0];
  int  max_i = [typeCells count] - 1;
  
  while (i < max_i) {
    [self moveCellDownFromIndex: i];
    i++;
  }

  [typesBrowser validateVisibleColumns];
  [self updateWindowState];
}

- (IBAction) moveToRevealAction: (id) sender {
  int  i = [typesBrowser selectedRowInColumn: 0];
  
  while (i > 0 && [[typeCells objectAtIndex: i] isDominated]) {
    [self moveCellUpFromIndex: i];
    i--;
  }
  
  [typesBrowser validateVisibleColumns];
  [self updateWindowState];
}

- (IBAction) moveToHideAction: (id) sender {
  int  i = [typesBrowser selectedRowInColumn: 0];
  int  max_i = [typeCells count] - 1;
  
  while (i < max_i && ![[typeCells objectAtIndex: i] isDominated]) {
    [self moveCellDownFromIndex: i];
    i++;
  }
  
  [typesBrowser validateVisibleColumns];
  [self updateWindowState];
}

- (IBAction) moveUpAction: (id) sender {
  int  i = [typesBrowser selectedRowInColumn: 0];
  
  if (i > 0) {
    [self moveCellUpFromIndex: i];
    i--;
  }
  
  [typesBrowser validateVisibleColumns];
  [self updateWindowState];
}

- (IBAction) moveDownAction: (id) sender {
  int  i = [typesBrowser selectedRowInColumn: 0];
  int  max_i = [typeCells count] - 1;
  
  if (i < max_i) {
    [self moveCellDownFromIndex: i];
    i++;
  }
  
  [typesBrowser validateVisibleColumns];
  [self updateWindowState];
}

- (IBAction) handleBrowserClick: (id) sender {
  [self updateWindowState];
}


//----------------------------------------------------------------------------
// Delegate methods for NSWindow

- (void) windowDidBecomeKey: (NSNotification *)notification {  
  if ([typeCells count] == 0) {
    // The window has just been opened. Fetch the latest type list.
    
    [self fetchCurrentTypeList];
    [self updateWindowState];
  }
}

//----------------------------------------------------------------------------
// Delegate methods for NSBrowser

- (BOOL) browser: (NSBrowser *)sender isColumnValid: (int) column {
  NSAssert(column==0, @"Invalid column.");
  NSAssert(sender == typesBrowser, @"Unexpected sender.");
    
  // When "validateVisibleColumns" is called, the visible column (just one)
  // can always be assumed to invalid.
  return NO;
}

- (int) browser: (NSBrowser *)sender numberOfRowsInColumn: (int) column {
  NSAssert(column == 0, @"Invalid column.");
  NSAssert(sender == typesBrowser, @"Unexpected sender.");
  
  return [typeCells count];
}

- (void) browser: (NSBrowser *)sender willDisplayCell: (id) cell 
           atRow: (int) row column: (int) column {
  NSAssert(column==0, @"Invalid column.");
  NSAssert(sender == typesBrowser, @"Unexpected sender.");
  
  TypeCell  *typeCell = [typeCells objectAtIndex: row];
  NSString  *uti = [[typeCell uniformType] uniformTypeIdentifier];

  NSMutableAttributedString  *cellValue = 
    [[[NSMutableAttributedString alloc] initWithString: uti] autorelease];

  if ([typeCell isDominated]) {
    [cellValue addAttribute: NSForegroundColorAttributeName
                 value: [NSColor grayColor] 
                 range: NSMakeRange(0, [cellValue length])];
  }
  
  [cell setAttributedStringValue: cellValue];
  
  [cell setLeaf: YES];
}

@end // @implementation EditUniformTypeRankingWindowControl



@implementation EditUniformTypeRankingWindowControl (PrivateMethods)

// Updates the window state to reflect the state of the uniform type ranking
- (void) fetchCurrentTypeList {
  [typeCells removeAllObjects];
  
  NSArray  *currentRanking = [typeRanking rankedUniformTypes];
  
  NSEnumerator  *typeEnum = [currentRanking objectEnumerator];
  UniformType  *type;
  while (type = [typeEnum nextObject]) {
    TypeCell  *typeCell = 
                 [[[TypeCell alloc] initWithUniformType: type] autorelease];

    [typeCells addObject: typeCell];
  }
  
  [self updateDominatedStatusInRange: NSMakeRange(0, [typeCells count])];
  
  [typesBrowser validateVisibleColumns];  
  [typesBrowser selectRow: 0 inColumn: 0];
}

// Commits changes made in the window to the uniform type ranking.
- (void) commitChangedTypeList {
  NSMutableArray  *newRanking = 
    [NSMutableArray arrayWithCapacity: [typeCells count]];
    
  NSEnumerator  *typeCellEnum = [typeCells objectEnumerator];
  TypeCell  *typeCell;
  while (typeCell = [typeCellEnum nextObject]) {
    [newRanking addObject: [typeCell uniformType]];
  }
  
  [typeRanking updateRankedUniformTypes: newRanking];
}


- (void) closeWindow {
  [[self window] close];
  
  // Clear the array. This signals that it should be reloaded when the window
  // appears again. This is needed because there is (apparently) no good way to
  // find out when a window has just been opened. The
  // NSWindowDidBecomeKeyNotification is used here, but this is also fired when
  // the window is already open (but lost and subsequently regained its key
  // status).
  [typeCells removeAllObjects];
}


- (void) updateWindowState {
  int  i = [typesBrowser selectedRowInColumn: 0];
  int  numCells =  [typeCells count];
  
  NSAssert(i >= 0 && i < numCells, @"Invalid selected type.");
  
  TypeCell  *typeCell = [typeCells objectAtIndex: i];
  
  [revealButton setEnabled: [typeCell isDominated]];
  [hideButton setEnabled: ( ![typeCell isDominated] && (i < numCells -1) ) ];

  [moveUpButton setEnabled: i > 0];
  [moveToTopButton setEnabled: i > 0];

  [moveDownButton setEnabled: i < numCells - 1];
  [moveToBottomButton setEnabled: i < numCells - 1];
}

- (void) updateDominatedStatusInRange: (NSRange) range {
  int  i = range.location;
  int  i_max = range.location + range.length;
  
  while (i < i_max) {
    TypeCell  *cell = [typeCells objectAtIndex: i];
    NSSet  *ancestors = [[cell uniformType] ancestorTypes];
  
    int  j = 0;
    BOOL  dominated = NO;

    while (j < i && !dominated) {
      UniformType  *higherType = [[typeCells objectAtIndex: j] uniformType];
    
      if ([ancestors containsObject: higherType]) {
        dominated = YES;
      }
    
      j++;
    }
    
    [cell setDominated: dominated];
  
    i++;
  }
}


- (void) moveCellUpFromIndex: (int) index {
  TypeCell  *upCell = [typeCells objectAtIndex: index];
  TypeCell  *downCell = [typeCells objectAtIndex: index - 1];
  
  // Swap the cells
  [typeCells exchangeObjectAtIndex: index withObjectAtIndex: index - 1];

  // Check if the dominated status of upCell changed.
  if ([upCell isDominated]) {
    NSSet  *ancestors = [[upCell uniformType] ancestorTypes];

    if ([ancestors containsObject: [downCell uniformType]]) {
      // downCell was an ancestor of upCell, so upCell may not be dominated
      // anymore.
      
      int  i = 0;
      int  max_i = index - 1;
      BOOL  dominated = NO;
      while (i < max_i && !dominated) {
        UniformType  *higherType = [[typeCells objectAtIndex: i] uniformType];
        
        if ([ancestors containsObject: higherType]) {
          dominated = YES;
        }
        
        i++;
      }
      
      if (! dominated) {
        [upCell setDominated: NO];
      }
    }
  }
  
  // Check if the dominated status of downCell changed.
  if (! [downCell isDominated]) {
    NSSet  *ancestors = [[downCell uniformType] ancestorTypes];
    
    if ([ancestors containsObject: [upCell uniformType]]) {
      [downCell setDominated: YES];
    }
  }
}

- (void) moveCellDownFromIndex: (int) index {
  [self moveCellUpFromIndex: index + 1];
}

@end // @implementation EditUniformTypeRankingWindowControl (PrivateMethods)


@implementation TypeCell

- (id) initWithUniformType: (UniformType *)typeVal {
  if (self = [super init]) {
    type = [typeVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [type release];
  
  [super dealloc];
}

- (UniformType *) uniformType {
  return type;
}

- (BOOL) isDominated {
  return isDominated;
}

- (void) setDominated: (BOOL) flag {
  isDominated = flag;
}

@end
