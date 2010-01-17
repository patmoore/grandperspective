#import "FiltersWindowControl.h"

#import "ControlConstants.h"
#import "NotifyingDictionary.h"

#import "Filter.h"
#import "NamedFilter.h"
#import "FilterEditor.h"
#import "FilterRepository.h"


@interface FiltersWindowControl (PrivateMethods)

// Returns the non-localized name of the selected available filter (if any).
- (NSString *)selectedFilterName;

- (void) selectFilterNamed:(NSString *)name;

- (void) updateWindowState;

- (void) filterAddedToRepository:(NSNotification *)notification;
- (void) filterRemovedFromRepository:(NSNotification *)notification;
- (void) filterUpdatedInRepository:(NSNotification *)notification;
- (void) filterRenamedInRepository:(NSNotification *)notification;

- (void) confirmFilterRemovalAlertDidEnd:(NSAlert *)alert 
           returnCode:(int) returnCode contextInfo:(void *)contextInfo;

@end // @interface EditFiltersWindowControl (PrivateMethods)


@implementation FiltersWindowControl

- (id) init {
  return [self initWithFilterRepository: [FilterRepository defaultInstance]];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithFilterRepository:(FilterRepository *)filterRepositoryVal {
  if (self = [super initWithWindowNibName: @"FiltersWindow" owner: self]) {
    filterRepository = [filterRepositoryVal retain];

    filterEditor = 
      [[FilterEditor alloc] initWithFilterRepository: filterRepository];

    NotifyingDictionary  *repositoryFiltersByName = 
      [filterRepository filtersByNameAsNotifyingDictionary];
    NSNotificationCenter  *nc = [repositoryFiltersByName notificationCenter];
    
    [nc addObserver: self selector: @selector(filterAddedToRepository:) 
          name: ObjectAddedEvent object: repositoryFiltersByName];
    [nc addObserver: self selector: @selector(filterRemovedFromRepository:) 
          name: ObjectRemovedEvent object: repositoryFiltersByName];
    [nc addObserver: self selector: @selector(filterUpdatedInRepository:) 
          name: ObjectUpdatedEvent object: repositoryFiltersByName];
    [nc addObserver: self selector: @selector(filterRenamedInRepository:) 
          name: ObjectRenamedEvent object: repositoryFiltersByName];

    filterNames = [[NSMutableArray alloc] initWithCapacity:
                      [[filterRepository filtersByName] count] + 8];
    [filterNames addObjectsFromArray: 
       [[filterRepository filtersByName] allKeys]];
    [filterNames sortUsingSelector: @selector(compare:)];
    
    filterNameToSelect = nil;
  }
  return self;
}

- (void) dealloc {
  NSNotificationCenter  *nc = 
    [[filterRepository filtersByNameAsNotifyingDictionary] notificationCenter];
  [nc removeObserver: self];
    
  [filterRepository release];
  
  [filterEditor release];

  [filterNames release];
  [filterNameToSelect release];
  
  [super dealloc];
}


- (IBAction) okAction:(id) sender {
  [[self window] close];
}


- (IBAction) addFilterToRepository:(id) sender {
  NamedFilter  *newFilter = [filterEditor newNamedFilter];
  
  [self selectFilterNamed: [newFilter name]];
  [[self window] makeFirstResponder: filterView];
}

- (IBAction) editFilterInRepository:(id) sender {
  NSString  *oldName = [self selectedFilterName];
  NamedFilter  *updatedFilter = [filterEditor editFilterNamed: oldName];
}

- (IBAction) removeFilterFromRepository:(id) sender {
  NSString  *filterName = [self selectedFilterName];  
  NSAlert  *alert = [[[NSAlert alloc] init] autorelease];
  NSString  *fmt = NSLocalizedString( @"Remove the filter named \"%@\"?",
                                      @"Alert message" );
  NSString  *infoMsg = 
    ([filterRepository applicationProvidedFilterForName: filterName] != nil) ?
      NSLocalizedString(
        @"The filter will be replaced by the default filter with this name.",
        @"Alert informative text" ) :
      NSLocalizedString( 
        @"The filter will be irrevocably removed from the filter repository.",
        @"Alert informative text" );

  NSBundle  *mainBundle = [NSBundle mainBundle];
  NSString  *localizedName = 
    [mainBundle localizedStringForKey: filterName value: nil table: @"Names"];
  
  [alert addButtonWithTitle: REMOVE_BUTTON_TITLE];
  [alert addButtonWithTitle: CANCEL_BUTTON_TITLE];
  [alert setMessageText: [NSString stringWithFormat: fmt, localizedName]];
  [alert setInformativeText: infoMsg];

  [alert beginSheetModalForWindow: [self window] modalDelegate: self
           didEndSelector: @selector(confirmFilterRemovalAlertDidEnd: 
                                       returnCode:contextInfo:) 
           contextInfo: filterName];
}

- (void) windowDidLoad {
  [filterView setDelegate: self];
  [filterView setDataSource: self];
      
  [self updateWindowState];
}


//----------------------------------------------------------------------------
// NSTableSource

- (int) numberOfRowsInTableView: (NSTableView *)tableView {
  return [filterNames count];
}

- (id) tableView: (NSTableView *)tableView 
         objectValueForTableColumn: (NSTableColumn *)column row: (int)row {
  NSString  *filterName = [filterNames objectAtIndex: row];
  NSBundle  *mainBundle = [NSBundle mainBundle];
  return 
    [mainBundle localizedStringForKey: filterName value: nil table: @"Names"];

}


//----------------------------------------------------------------------------
// Delegate methods for NSTable

- (void) tableViewSelectionDidChange: (NSNotification *)notification {
  [self updateWindowState];
}

@end // @implementation EditFiltersWindowControl


@implementation FiltersWindowControl (PrivateMethods)

- (NSString *)selectedFilterName {
  int  index = [filterView selectedRow];
  return (index < 0) ? nil : [filterNames objectAtIndex: index];
}


- (void) selectFilterNamed:(NSString *)name {
  int  row = [filterNames indexOfObject: name];
  if (row >= 0) {
    [filterView selectRow: row byExtendingSelection: NO];
  }
  else {
    [filterView deselectAll: self];
  }
}

- (void) updateWindowState {
  NSString  *filterName = [self selectedFilterName];
  
  [editFilterButton setEnabled: (filterName != nil) ];
  
  [removeFilterButton setEnabled: 
     (filterName != nil &&
        ( [filterRepository applicationProvidedFilterForName: filterName] !=
          [filterRepository filterForName: filterName] ))];
}


- (void) filterAddedToRepository:(NSNotification *)notification {
  NSString  *name = [[notification userInfo] objectForKey: @"key"];
  NSString  *selectedName = [self selectedFilterName];

  [filterNames addObject: name];

  // Ensure that the filters remain sorted.
  [filterNames sortUsingSelector: @selector(compare:)];
  [filterView reloadData];
        
  if (selectedName != nil) {
    // Make sure that the same filter is still selected.
    [self selectFilterNamed: selectedName];
  }
                
  [self updateWindowState];
}


- (void) filterRemovedFromRepository:(NSNotification *)notification {
  NSString  *name = [[notification userInfo] objectForKey: @"key"];
  NSString  *selectedName = [self selectedFilterName];

  int  index = [filterNames indexOfObject: name];
  NSAssert(index != NSNotFound, @"Filter not found.");

  [filterNames removeObjectAtIndex: index];
  [filterView reloadData];
  
  if ([name isEqualToString: selectedName]) {
    // The removed filter was selected. Clear the selection.
    [filterView deselectAll: self];
  }
  else if (selectedName != nil) {
    // Make sure that the same filter is still selected.
    [self selectFilterNamed: selectedName];
  }

  [self updateWindowState];
}


- (void) filterUpdatedInRepository:(NSNotification *)notification {
  [self updateWindowState];
}


- (void) filterRenamedInRepository:(NSNotification *)notification {
  NSString  *oldName = [[notification userInfo] objectForKey: @"oldkey"];
  NSString  *newName = [[notification userInfo] objectForKey: @"newkey"];

  int  index = [filterNames indexOfObject: oldName];
  NSAssert(index != NSNotFound, @"Filter not found.");

  NSString  *selectedName = [self selectedFilterName];

  [filterNames replaceObjectAtIndex: index withObject: newName];
  [filterNames sortUsingSelector: @selector(compare:)];
  [filterView reloadData];
    
  if ([selectedName isEqualToString: oldName]) {
    // It was selected, so make sure it still is.
    selectedName = newName;
  }
  if (selectedName != nil) {
    // Make sure that the same test is still selected.
    [self selectFilterNamed: selectedName];
  }
}


- (void) confirmFilterRemovalAlertDidEnd:(NSAlert *)alert 
          returnCode:(int) returnCode contextInfo:(void *)filterName {
  if (returnCode == NSAlertFirstButtonReturn) {
    // Delete confirmed.
    
    Filter  *defaultFilter = 
      [filterRepository applicationProvidedFilterForName: filterName];
    NotifyingDictionary  *repositoryFiltersByName = 
      [filterRepository filtersByNameAsNotifyingDictionary];
    
    if (defaultFilter == nil) {
      [repositoryFiltersByName removeObjectForKey: filterName];
    }
    else {
      // Replace it by the application-provided filter with the same name
      // (this would happen anyway when the application is restarted).
      [repositoryFiltersByName updateObject: defaultFilter forKey: filterName];
    }

    // Rest of delete handled in response to notification event.
  }
}

@end // @implementation EditFiltersWindowControl (PrivateMethods)

