#import <Cocoa/Cocoa.h>

extern NSString  *SelectedFilterRenamed;
extern NSString  *SelectedFilterRemoved;
extern NSString  *SelectedFilterUpdated;

@class FilterRepository;
@class UniqueTagsTransformer;

/* Controller for a pop-up button for selecting the filters in the filter
 * repository. It observes the repository and updates the button when filters
 * are added, removed or renamed. It also fires events itself when the
 * selected filter is either renamed, removed or updated. Where available, the 
 * pop-up shows the localized names of the filters.
 */
@interface FilterPopUpControl : NSObject {
  NSPopUpButton  *popUpButton;
  FilterRepository  *filterRepository;
  UniqueTagsTransformer  *tagMaker;
  
  NSNotificationCenter  *notificationCenter;
}

- (id) initWithPopUpButton:(NSPopUpButton *)popUpButton 
         filterRepository:(FilterRepository *)filterRepository;

- (NSNotificationCenter *)notificationCenter; 
- (void) setNotificationCenter:(NSNotificationCenter *)notificationCenter; 

/* Returns the non-localized name of the selected filter.
 */
- (NSString *)selectedFilterName;

@end
