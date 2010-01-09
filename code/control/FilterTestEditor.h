#import <Cocoa/Cocoa.h>


@class EditFilterTestWindowControl;
@class FilterTestRepository;
@class FilterTest;


/* Helper class for editing filter tests. Its purpose and functionality is
 * very similar to that of the FilterEditor class.
 */
@interface FilterTestEditor : NSObject {
  FilterTestRepository  *testRepository;
  
  EditFilterTestWindowControl  *editTestWindowControl;
}

- (id) init;
- (id) initWithFilterTestRepository:(FilterTestRepository *)testRepository;

/* Edits a new filter test. It returns the new test, or "nil" if the action was
 * cancelled. It updates the repository. The repository's NotifyingDictionary 
 * will fire an "objectAdded" event in response.
 */
- (FilterTest *)newFilterTest;

/* Edits an existing test with the given name. The test should exist in the
 * test repository. It returns the modified test, or "nil" if the action was
 * cancelled. It updates the filter in the repository. Its NotifyingDictionary
 * will fire the appropriate event(s) in response.
 */
- (FilterTest *)editFilterTestNamed:(NSString *)oldName;

@end
