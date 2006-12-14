#import <Cocoa/Cocoa.h>

@class FileItem;

// Instances implementing this protocol should be immutable. Their 
// configuration should remain fixed throughout their lifetime, but
// furthermore, they should not maintain any state (e.g. for performance
// optimalisation). The latter is forbidden, as the same test may be
// used in multiple threads concurrently.
@protocol FileItemTest

// A context is passed, which may provide additional information and/or
// state used by the test. See the ItemPathTest class for an example.
- (BOOL) testFileItem: (FileItem *)item context: (id)context;

- (NSString *) name;
- (void) setName: (NSString *)name;

// Used for storing object to preferences.
- (NSDictionary *) dictionaryForObject;

@end
