#import <Cocoa/Cocoa.h>

@class FilterWindowControl;
@class FilterRepository;
@class NamedFilter;

/* Helper class for editing filters. For a clean separation of concerns, the 
 * EditFilterWindowControl only manages the process editing of a single filter, 
 * without concerning itself with the large context (i.e. the filter repository 
 * that the filter will be added to). The interaction with the filter 
 * repository (e.g. ensuring that the name of a new filter does not clash with
 * that of an existing one) is the responsibility of this class.
 */
@interface FilterEditor : NSObject {
  FilterRepository  *filterRepository;
  
  FilterWindowControl  *filterWindowControl;
}

- (id) init;
- (id) initWithFilterRepository:(FilterRepository *)filterRepository;

/* Edits a new filter. It returns the new filter, or "nil" if the action was
 * cancelled. It updates the repository. The repository's NotifyingDictionary 
 * will fire an "objectAdded" event in response.
 */
- (NamedFilter *)newNamedFilter;

/* Edits an existing filter with the given name. The filter should exist in
 * the filter repository. It returns the modified filter, or "nil" if the 
 * action was cancelled. It updates the filter in the repository. Its
 * NotifyingDictionary will fire the appropriate event(s) in response.
 */
- (NamedFilter *)editFilterNamed:(NSString *)oldName;

@end
