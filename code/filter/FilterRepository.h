#import <Cocoa/Cocoa.h>

@class NotifyingDictionary;
@class Filter;

@interface FilterRepository : NSObject {
  NotifyingDictionary  *filtersByName;

  // Contains the filters provided by the application.
  NSDictionary  *applicationProvidedFilters;
}

+ (FilterRepository *)defaultFilterRepository;

- (NotifyingDictionary *)filtersByNameAsNotifyingDictionary;

- (Filter *)filterForName:(NSString *)name;

- (Filter *)applicationProvidedFilterForName:(NSString *)name;

- (void) storeUserCreatedFilters;

@end