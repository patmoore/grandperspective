#import "UniformTypeRankingWindowControl.h"

#import "UniformTypeRanking.h"
#import "UniformType.h"


NSString  *InternalTableDragType = @"EditUniformTypeRankingWindowInternalDrag";


@interface TypeCell : NSObject {
  UniformType  *type;
  BOOL  dominated;
}

- (id) initWithUniformType: (UniformType *)type dominated: (BOOL) dominated;

- (UniformType *) uniformType;
- (BOOL) isDominated;
- (void) setDominated: (BOOL) flag;

@end


@interface UniformTypeRankingWindowControl (PrivateMethods)

- (void) fetchCurrentTypeList;
- (void) commitChangedTypeList;

- (void) closeWindow;

- (void) updateWindowState;

- (void) moveCellUpFromIndex: (int) index;
- (void) moveCellDownFromIndex: (int) index;
- (void) movedCellToIndex: (int) index;

- (int) getRowNumberFromDraggingInfo: (id <NSDraggingInfo>) info;

@end


@implementation UniformTypeRankingWindowControl

- (id) init {
  return [self initWithUniformTypeRanking:
                   [UniformTypeRanking defaultUniformTypeRanking]];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithUniformTypeRanking: (UniformTypeRanking *)typeRankingVal {
  if (self = [super initWithWindowNibName: @"UniformTypeRankingWindow" 
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
  [typesTable setDelegate: self];
  [typesTable setDataSource: self];
  
  [typesTable registerForDraggedTypes: 
                [NSArray arrayWithObject: InternalTableDragType]];
}


- (IBAction) cancelAction: (id) sender {
  [self closeWindow];
}

- (IBAction) okAction: (id) sender {
  [self commitChangedTypeList];

  [self closeWindow];
}

- (IBAction) moveToTopAction: (id) sender {
  int  i = [typesTable selectedRow];
  
  while (i > 0) {
    [self moveCellUpFromIndex: i];
    i--;
  }
  
  [self movedCellToIndex: i];
}

- (IBAction) moveToBottomAction: (id) sender {
  int  i = [typesTable selectedRow];
  int  max_i = [typeCells count] - 1;
  
  while (i < max_i) {
    [self moveCellDownFromIndex: i];
    i++;
  }

  [self movedCellToIndex: i];
}

- (IBAction) moveToRevealAction: (id) sender {
  int  i = [typesTable selectedRow];
  
  while (i > 0 && [[typeCells objectAtIndex: i] isDominated]) {
    [self moveCellUpFromIndex: i];
    i--;
  }
  
  [self movedCellToIndex: i];
}

- (IBAction) moveToHideAction: (id) sender {
  int  i = [typesTable selectedRow];
  int  max_i = [typeCells count] - 1;
  
  while (i < max_i && ![[typeCells objectAtIndex: i] isDominated]) {
    [self moveCellDownFromIndex: i];
    i++;
  }
  
  [self movedCellToIndex: i];
}

- (IBAction) moveUpAction: (id) sender {
  int  i = [typesTable selectedRow];
  
  if (i > 0) {
    [self moveCellUpFromIndex: i];
    i--;
  }
  
  [self movedCellToIndex: i];
}

- (IBAction) moveDownAction: (id) sender {
  int  i = [typesTable selectedRow];
  int  max_i = [typeCells count] - 1;
  
  if (i < max_i) {
    [self moveCellDownFromIndex: i];
    i++;
  }
  
  [self movedCellToIndex: i];
}


- (IBAction) showTypeDescriptionChanged: (id) sender {
  NSButton  *button = sender;
  if ([button state] == NSOffState) {
    [typeDescriptionDrawer close];
  }
  else if ([button state] == NSOnState) {
    [typeDescriptionDrawer open];
  }
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
// NSTableSource

- (int) numberOfRowsInTableView: (NSTableView *)tableView {
  return [typeCells count];
}

- (id) tableView: (NSTableView *)tableView 
         objectValueForTableColumn: (NSTableColumn *)column row: (int)row {
  return [[[typeCells objectAtIndex: row] uniformType] uniformTypeIdentifier];
}


- (BOOL)tableView: (NSTableView *)tableView
          writeRows: (NSArray *)rows toPasteboard: (NSPasteboard *)pboard {
  // Note: This method is deprecated in Mac OS X 10.4 where 
  // tableView:writeRowsWithIndexes:toPasteboard: should be used instead. For
  // now, however, we want to support Mac OS X 10.3 as well.

  // Store the source row number of the type that is being dragged.
  NSNumber  *rowNum = (NSNumber *)[rows objectAtIndex: 0];
  NSData  *data = [NSKeyedArchiver archivedDataWithRootObject: rowNum];

  [pboard declareTypes: [NSArray arrayWithObject: InternalTableDragType]
            owner: self];
  [pboard setData: data forType: InternalTableDragType];

  return YES;
}

- (NSDragOperation) tableView: (NSTableView *)tableView
                      validateDrop: (id <NSDraggingInfo>) info
                      proposedRow: (int) row
                      proposedDropOperation: (NSTableViewDropOperation) op {
  if (op == NSTableViewDropAbove) {
    // Only allow drops in between two existing rows as otherwise it is not
    // clear to the user where the dropped item will be moved to.
  
    int  fromRow = [self getRowNumberFromDraggingInfo: info];
    if (row < fromRow || row > fromRow + 1) {
      // Only allow drops that actually result in a move.
      
      return NSDragOperationMove;
    }
  }

  return NSDragOperationNone;
}

- (BOOL) tableView: (NSTableView *)tableView
           acceptDrop: (id <NSDraggingInfo>) info row: (int) row
           dropOperation: (NSTableViewDropOperation) op {

  int  i = [self getRowNumberFromDraggingInfo: info];

  if (i > row) {
    while (i > row) {
      [self moveCellUpFromIndex: i];
      i--;
    }
  }
  else {
    int  max_i = row - 1;
    while (i < max_i) {
      [self moveCellDownFromIndex: i];
      i++;
    }
  }
  
  [self movedCellToIndex: i];
  
  return YES;
}


//----------------------------------------------------------------------------
// Delegate methods for NSTable

- (void) tableView: (NSTableView *)tableView willDisplayCell: (id) cell 
           forTableColumn: (NSTableColumn *)aTableColumn row: (int) row {
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
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification {
  [self updateWindowState];
}

@end // @implementation EditUniformTypeRankingWindowControl



@implementation UniformTypeRankingWindowControl (PrivateMethods)

// Updates the window state to reflect the state of the uniform type ranking
- (void) fetchCurrentTypeList {
  [typeCells removeAllObjects];
  
  NSArray  *currentRanking = [typeRanking rankedUniformTypes];
  
  NSEnumerator  *typeEnum = [currentRanking objectEnumerator];
  UniformType  *type;
  while (type = [typeEnum nextObject]) {
    BOOL  dominated = [typeRanking isUniformTypeDominated: type];
    TypeCell  *typeCell = 
                 [[[TypeCell alloc] initWithUniformType: type
                                      dominated: dominated] autorelease];

    [typeCells addObject: typeCell];
  }
  
  [typesTable reloadData]; 
  [typesTable selectRow: 0 byExtendingSelection: NO];
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
  int  i = [typesTable selectedRow];
  int  numCells =  [typeCells count];
  
  NSAssert(i >= 0 && i < numCells, @"Invalid selected type.");
  
  TypeCell  *typeCell = [typeCells objectAtIndex: i];
  
  [revealButton setEnabled: [typeCell isDominated]];
  [hideButton setEnabled: ( ![typeCell isDominated] && (i < numCells -1) ) ];

  [moveUpButton setEnabled: i > 0];
  [moveToTopButton setEnabled: i > 0];

  [moveDownButton setEnabled: i < numCells - 1];
  [moveToBottomButton setEnabled: i < numCells - 1];
  
  UniformType  *type = [typeCell uniformType];
  
  [typeIdentifierField setStringValue: [type uniformTypeIdentifier]];
  
  NSString  *descr = [type description];
  [typeDescriptionField setStringValue: (descr != nil) ? descr : @""];

  NSMutableString  *conformsTo = [NSMutableString stringWithCapacity: 64];
  NSEnumerator  *parentEnum = [[type parentTypes] objectEnumerator];
  UniformType  *parentType;
  while (parentType = [parentEnum nextObject]) {
    if ([conformsTo length] > 0) {
      [conformsTo appendString: @", "];
    }
    [conformsTo appendString: [parentType uniformTypeIdentifier]];
  }
  [typeConformsToField setStringValue: conformsTo];
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

/* Update the window after a cell has been moved.
 */
- (void) movedCellToIndex: (int) index { 
  [typesTable selectRow: index byExtendingSelection: NO];
  [typesTable reloadData];
  [self updateWindowState];
}


- (int) getRowNumberFromDraggingInfo: (id <NSDraggingInfo>) info {
  NSPasteboard  *pboard = [info draggingPasteboard];
  NSData  *data = [pboard dataForType: InternalTableDragType];
  NSNumber  *rowNum = [NSKeyedUnarchiver unarchiveObjectWithData: data];
  
  return [rowNum intValue];
}

@end // @implementation EditUniformTypeRankingWindowControl (PrivateMethods)


@implementation TypeCell

- (id) initWithUniformType: (UniformType *)typeVal
         dominated: (BOOL) dominatedVal {
  if (self = [super init]) {
    type = [typeVal retain];
    dominated = dominatedVal;
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
  return dominated;
}

- (void) setDominated: (BOOL) flag {
  dominated = flag;
}

@end
