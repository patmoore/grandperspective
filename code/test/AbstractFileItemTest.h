#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"

@interface AbstractFileItemTest : NSObject<FileItemTest> {

}

// Helper methods for storing and restoring objects from preferences. These
// are meant to be used and overridden by subclasses, and should not be 
// called directly.
- (id) initWithPropertiesFromDictionary: (NSDictionary *)dict;
- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict;

@end
