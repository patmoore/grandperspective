#import <Cocoa/Cocoa.h>

/* Protocol for validating names of filters and/or tests. It has been created
 * so that the window for editing a filter (or filter test) does not need a
 * direct reference to the set of filters (or the set of filter tests) in  
 * order to decide if the name of the filter (or filter test) does not clash
 * with that of existing filters (or filter tests).
 */
@protocol NameValidator

/* Checks if the name (of a new or modified filter or filter test) is valid 
 * (given the current set of filters and tests). Returns a (localized) error
 * message if not, and "nil" otherwise.
 */
- (NSString *)checkNameIsValid:(NSString *)name;

@end // @protocol NameValidator
