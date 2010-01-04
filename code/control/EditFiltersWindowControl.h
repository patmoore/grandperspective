#import <Cocoa/Cocoa.h>

@class EditFilterWindowControl;
@class FilterRepository;
@class NotifyingDictionary;

@interface EditFiltersWindowControl : NSWindowController {

  IBOutlet NSButton  *editFilterButton;
  IBOutlet NSButton  *removeFilterButton;

  IBOutlet NSTableView  *filterView;
  
  EditFilterWindowControl  *editFilterWindowControl;
  
  FilterRepository  *filterRepository;
  NotifyingDictionary  *repositoryFiltersByName;
  
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
