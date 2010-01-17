#import <Cocoa/Cocoa.h>

@class NamedFilter;
@class FilterRepository;
@class FilterEditor;
@class FilterPopUpControl;

@interface FilterSelectionPanelControl : NSWindowController {
  IBOutlet NSPopUpButton  *filterPopUp;

  FilterRepository  *filterRepository;

  FilterEditor  *filterEditor;
  FilterPopUpControl  *filterPopUpControl;
}

- (id) init;
- (id) initWithFilterRepository:(FilterRepository *)filterRepository;

- (IBAction) editFilter:(id) sender;
- (IBAction) addFilter:(id) sender;

- (IBAction) okAction:(id) sender;
- (IBAction) cancelAction:(id) sender;

- (void) selectFilterNamed:(NSString *)name;

/* Returns the filter that has been selected.
 */
- (NamedFilter *)selectedNamedFilter;

@end
