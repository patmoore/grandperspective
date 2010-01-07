#import <Cocoa/Cocoa.h>

@class FilterRepository;
@class FilterEditor;

@interface EditFiltersWindowControl : NSWindowController {

  IBOutlet NSButton  *editFilterButton;
  IBOutlet NSButton  *removeFilterButton;

  IBOutlet NSTableView  *filterView;
  
  FilterRepository  *filterRepository;
  
  FilterEditor  *filterEditor;
  
  // The data in the table view (names of the filters as NSString)
  NSMutableArray  *filterNames;

  // Non-localized name of filter to select.
  NSString  *filterNameToSelect;
}

- (id) init;
- (id) initWithFilterRepository:(FilterRepository *)filterRepository;

- (IBAction) okAction:(id) sender;

- (IBAction) addFilterToRepository:(id) sender;
- (IBAction) editFilterInRepository:(id) sender;
- (IBAction) removeFilterFromRepository:(id) sender;

@end // @interface EditFiltersWindowControl
