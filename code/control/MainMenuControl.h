#import <Cocoa/Cocoa.h>

@class WindowManager;
@class VisibleAsynchronousTaskManager;
@class FiltersWindowControl;
@class UniformTypeRankingWindowControl;
@class FilterSelectionPanelControl;
@class PreferencesPanelControl;

@interface MainMenuControl : NSObject {
  WindowManager  *windowManager;
  
  VisibleAsynchronousTaskManager  *scanTaskManager;
  VisibleAsynchronousTaskManager  *filterTaskManager;
  VisibleAsynchronousTaskManager  *writeTaskManager;
  VisibleAsynchronousTaskManager  *readTaskManager;
  
  PreferencesPanelControl  *preferencesPanelControl;
  FilterSelectionPanelControl  *filterSelectionPanelControl;
  FiltersWindowControl  *filtersWindowControl;
  UniformTypeRankingWindowControl  *uniformTypeWindowControl;
  
  BOOL  scanAfterLaunch;
}

+ (MainMenuControl *)singletonInstance;

+ (NSArray *)rescanBehaviourNames;

+ (void) reportUnboundFilters:(NSArray *)unboundFilters;
+ (void) reportUnboundTests:(NSArray *)unboundTests;

- (IBAction) scanDirectoryView:(id) sender;
- (IBAction) scanFilteredDirectoryView:(id) sender;

// Default rescan action
- (IBAction) rescan:(id) sender;

// Rescan entire scan tree
- (IBAction) rescanDirectoryView:(id) sender;

// Rescan visible tree
- (IBAction) rescanDirectoryInView:(id) sender;

// Rescan selected item (file or directory)
- (IBAction) rescanSelectedFile:(id) sender;

- (IBAction) filterDirectoryView:(id) sender;
- (IBAction) duplicateDirectoryView:(id) sender;
- (IBAction) twinDirectoryView:(id) sender;

- (IBAction) saveScanData:(id) sender;
- (IBAction) loadScanData:(id) sender;

- (IBAction) saveDirectoryViewImage:(id) sender;

- (IBAction) editPreferences:(id) sender;
- (IBAction) editFilters:(id) sender;
- (IBAction) editUniformTypeRanking:(id) sender;

- (IBAction) toggleToolbarShown:(id) sender;
- (IBAction) customizeToolbar:(id) sender;

- (IBAction) openWebsite:(id) sender;

@end
