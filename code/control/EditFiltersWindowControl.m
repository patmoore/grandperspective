#import "EditFiltersWindowControl.h"

#import "ControlConstants.h"
#import "NameValidator.h"
#import "ModalityTerminator.h"
#import "NotifyingDictionary.h"

#import "Filter.h"
#import "NamedFilter.h"
#import "FilterRepository.h"

#import "EditFilterWindowControl.h"


@interface FilterNameValidator : NSObject <NameValidator> {
  NSDictionary  *allFilters;
  NSString  *allowedName;
}

- (id) initWithExistingFilters:(NSDictionary *)allFilters;
- (id) initWithExistingFilters:(NSDictionary *)allFilters 
         allowedName:(NSString *)name;

@end // @interface FilterNameValidator


@interface EditFiltersWindowControl (PrivateMethods)

- (NSWindow *)loadEditFilterWindow;

// Returns the non-localized name of the selected available filter (if any).
- (NSString *)selectedFilterName;

- (void) updateWindowState;

- (void) filterAddedToRepository:(NSNotification *)notification;
- (void) filterRemovedFromRepository:(NSNotification *)notification;
- (void) filterUpdatedInRepository:(NSNotification *)notification;
- (void) filterRenamedInRepository:(NSNotification *)notification;

- (void) confirmFilterRemovalAlertDidEnd:(NSAlert *)alert 
           returnCode:(int) returnCode contextInfo:(void *)contextInfo;

@end // @interface EditFiltersWindowControl (PrivateMethods)


@implementation EditFiltersWindowControl

- (id) init {
  return [self initWithFilterRepository: [FilterRepository defaultInstance]];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithFilterRepository:(FilterRepository *)filterRepositoryVal {
  if (self = [super initWithWindowNibName: @"EditFiltersWindow" owner: self]) {
    editFilterWindowControl = nil; // Load it lazily
  
    filterRepository = [filterRepositoryVal retain];
    repositoryFiltersByName = 
      [[filterRepository filtersByNameAsNotifyingDictionary] retain];

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
  [editFilterWindowControl release];

  [filterRepository release];
  [repositoryFiltersByName release];
  
  [filterNames release];
  [filterNameToSelect release];
  
  [super dealloc];
}


- (IBAction) okAction:(id) sender {
  [[self window] close];
}


- (IBAction) addFilterToRepository:(id) sender {
  NSWindow  *editFilterWindow = [self loadEditFilterWindow];
  
  FilterNameValidator  *nameValidator = 
    [[[FilterNameValidator alloc]
        initWithExistingFilters: [filterRepository filtersByName]]
          autorelease];
  
  [editFilterWindowControl setNameValidator: nameValidator];
  [editFilterWindowControl representEmptyFilter];

  [ModalityTerminator 
     modalityTerminatorForEventSource: editFilterWindowControl];
  int  status = [NSApp runModalForWindow: editFilterWindow];
  [editFilterWindow close];

  if (status == NSRunStoppedResponse) {
    NamedFilter  *namedFilter = [editFilterWindowControl createNamedFilter];
    
    if (namedFilter != nil) {
      NSString  *name = [namedFilter name];

      // The nameValidator should have ensured that this check succeeds.
      NSAssert( [[filterRepository filtersByName] objectForKey: name] == nil,
                @"Duplicate name check failed.");

      [filterNameToSelect release];
      filterNameToSelect = [name retain];

      [[filterRepository filtersByNameAsNotifyingDictionary]
          addObject: [namedFilter filter] forKey: name];
        
      // Rest of addition handled in response to notification event.
    }
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }  
}

- (IBAction) editFilterInRepository:(id) sender {
  NSWindow  *editFilterWindow = [self loadEditFilterWindow];

  NSString  *oldName = [self selectedFilterName];
  Filter  *oldFilter = [[filterRepository filtersByName] objectForKey: oldName];

  NamedFilter  *oldNamedFilter = 
    [NamedFilter namedFilter: oldFilter name: oldName];
  [editFilterWindowControl representNamedFilter: oldNamedFilter];

  if ([filterRepository applicationProvidedFilterForName: oldName] != nil) {
    // The filter's name equals that of an application provided filter. Show 
    // the localized version of the name (which implicitly prevents the name
    // from being changed).  
    NSBundle  *mainBundle = [NSBundle mainBundle];
    NSString  *localizedName = 
      [mainBundle localizedStringForKey: oldName value: nil table: @"Names"];
      
    [editFilterWindowControl setVisibleName: localizedName];
  }
  
  FilterNameValidator  *testNameValidator = 
    [[[FilterNameValidator alloc]
        initWithExistingFilters: [filterRepository filtersByName]
          allowedName: oldName] autorelease];
  [editFilterWindowControl setNameValidator: testNameValidator];
  
  [ModalityTerminator
     modalityTerminatorForEventSource: editFilterWindowControl];
  int  status = [NSApp runModalForWindow: editFilterWindow];
  [editFilterWindow close];
    
  if (status == NSRunStoppedResponse) {
    NamedFilter  *newNamedFilter = [editFilterWindowControl createNamedFilter];
    
    if (newNamedFilter != nil) {
      NSString  *newName = [newNamedFilter name];

      // The testNameValidator should have ensured that this check succeeds.
      NSAssert( 
        [newName isEqualToString: oldName] ||
        [[filterRepository filtersByName] objectForKey: newName] == nil,
        @"Duplicate name check failed.");

      if (! [newName isEqualToString: oldName]) {
        // Handle name change.
        [repositoryFiltersByName moveObjectFromKey: oldName toKey: newName];
          
        // Rest of rename handled in response to update notification event.
      }
        
      // Filter itself has changed as well.
      Filter  *newFilter = [newNamedFilter filter];
      [repositoryFiltersByName updateObject: newFilter forKey: newName];

      // Rest of update handled in response to update notification event.
    }
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }  
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
  return [filterNames objectAtIndex: row];
}


//----------------------------------------------------------------------------
// Delegate methods for NSTable

- (void) tableViewSelectionDidChange: (NSNotification *)notification {
  [self updateWindowState];
}

@end // @implementation EditFiltersWindowControl


@implementation EditFiltersWindowControl (PrivateMethods)

- (NSWindow *)loadEditFilterWindow {
  if (editFilterWindowControl == nil) {
    editFilterWindowControl = [[EditFilterWindowControl alloc] init];
  }
  // Return its window. This also ensure that it is loaded before its control 
  // is used.
  return [editFilterWindowControl window];
}

- (NSString *)selectedFilterName {
  int  index = [filterView selectedRow];
  return (index < 0) ? nil : [filterNames objectAtIndex: index];
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
        
  if ([filterNameToSelect isEqualToString: name]) { 
    // Select the newly added test.
    [filterView selectRow: [filterNames indexOfObject: name]
                              byExtendingSelection: NO];
    [[self window] makeFirstResponder: filterView];

    [filterNameToSelect release];
    filterNameToSelect = nil;
  }
  else if (selectedName != nil) {
    // Make sure that the same filter is still selected.
    [filterView selectRow: [filterNames indexOfObject: selectedName]
                              byExtendingSelection: NO];
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
    [filterView selectRow: [filterNames indexOfObject: selectedName]
                  byExtendingSelection: NO];
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
    [filterView selectRow: [filterNames indexOfObject: selectedName]
                  byExtendingSelection: NO];
  }
}


- (void) confirmFilterRemovalAlertDidEnd:(NSAlert *)alert 
          returnCode:(int) returnCode contextInfo:(void *)filterName {
  if (returnCode == NSAlertFirstButtonReturn) {
    // Delete confirmed.
    
    Filter  *defaultFilter = 
      [filterRepository applicationProvidedFilterForName: filterName];
    
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


@implementation FilterNameValidator

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithExistingFilters: instead.");
}

- (id) initWithExistingFilters:(NSDictionary *)allFiltersVal {
  return [self initWithExistingFilters: allFiltersVal allowedName: nil];
}

- (id) initWithExistingFilters:(NSDictionary *)allFiltersVal
         allowedName:(NSString *)name {
  if (self = [super init]) {
    allFilters = [allFiltersVal retain];
    allowedName = [name retain];    
  }
  
  return self;
}

- (void) dealloc {
  [allFilters release];
  [allowedName release];

  [super dealloc];
}


- (NSString *)checkNameIsValid:(NSString *)name {
  NSString*  errorText = nil;

  if ([name isEqualToString:@""]) {
    return NSLocalizedString(@"The filter must have a name.",
                             @"Alert message" );
  }
  else if ( ![allowedName isEqualToString: name] &&
            [allFilters objectForKey: name] != nil) {
    NSString  *fmt = NSLocalizedString(@"A filter named \"%@\" already exists.",
                                       @"Alert message");
    return [NSString stringWithFormat: fmt, name];
  }
  
  // All OK
  return nil;
}

@end // @implementation FilterNameValidator
