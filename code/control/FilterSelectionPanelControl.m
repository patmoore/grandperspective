#import "FilterSelectionPanelControl.h"

#import "NamedFilter.h"
#import "FilterRepository.h"
#import "FilterEditor.h"
#import "FilterPopUpControl.h"


@interface FilterSelectionPanelControl (PrivateMethods)

- (FilterEditor *)filterEditor;

@end // @interface SelectFilterPanelControl


@implementation FilterSelectionPanelControl

- (id) init {
  return [self initWithFilterRepository: [FilterRepository defaultInstance]];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithFilterRepository:(FilterRepository *)filterRepositoryVal {
  if (self = [super initWithWindowNibName: @"FilterSelectionPanel" 
                      owner: self]) {
    filterRepository = [filterRepositoryVal retain];

    filterEditor = nil; // Load it lazily
  }
  return self;
}

- (void) dealloc {
  [filterRepository release];
  [filterEditor release];
  [filterPopUpControl release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  filterPopUpControl = 
    [[FilterPopUpControl alloc] initWithPopUpButton: filterPopUp
                                  filterRepository: filterRepository];
}


- (IBAction) editFilter:(id) sender {
  [self filterEditor];
  NSString  *oldName = [filterPopUpControl selectedFilterName];
  NamedFilter  *updatedFilter = [filterEditor editFilterNamed: oldName];
}

- (IBAction) addFilter:(id) sender {
  [self filterEditor];
  NamedFilter  *newFilter = [filterEditor newNamedFilter];
  [self selectFilterNamed: [newFilter name]];
}

- (IBAction) okAction:(id) sender {
  [NSApp stopModal];
}

- (IBAction) cancelAction:(id) sender {
  [NSApp abortModal];
}


- (void) selectFilterNamed:(NSString *)name {
  return [filterPopUpControl selectFilterNamed: name];
}

- (NamedFilter *)selectedNamedFilter {
  NSString  *name = [filterPopUpControl selectedFilterName];
  Filter  *filter = [[filterRepository filtersByName] objectForKey: name];
  return [NamedFilter namedFilter: filter name: name];                        
}

@end // @implementation SelectFilterPanelControl


@implementation FilterSelectionPanelControl (PrivateMethods)

- (FilterEditor *)filterEditor {
  if (filterEditor == nil) {
    filterEditor = 
      [[FilterEditor alloc] initWithFilterRepository: filterRepository];
  }
  return filterEditor;
}

@end // @implementation SelectFilterPanelControl (PrivateMethods)
