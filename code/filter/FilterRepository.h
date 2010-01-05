#import <Cocoa/Cocoa.h>

@class NotifyingDictionary;
@class Filter;

@interface FilterRepository : NSObject {
  NotifyingDictionary  *filtersByName;

  // Contains the filters provided by the application.
  NSDictionary  *applicationProvidedFilters;
}

+ (id) defaultInstance;

/* Returns dictionary which can subsequently be modified.
 */
- (NotifyingDictionary *)filtersByNameAsNotifyingDictionary;

/* Returns dictionary as an NSDictionary, which is useful if the dictionary
 * does not need to be modified. Note, the dictionary can still be modified
 * by casting it to NotifyingDictionary. This is only a convenience method.
 */
- (NSDictionary *)filtersByName;

- (Filter *)filterForName:(NSString *)name;

- (Filter *)applicationProvidedFilterForName:(NSString *)name;

- (void) storeUserCreatedFilters;

@end