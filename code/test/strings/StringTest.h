#import <Cocoa/Cocoa.h>


/* Abstract class for tests on string values.
 */
@interface StringTest : NSObject {
}

+ (StringTest *)stringTestFromDictionary:(NSDictionary *)dict;
@end


@interface StringTest (AbstractMethods)

- (BOOL) testString:(NSString *)string;

- (NSString *)descriptionWithSubject:(NSString *)subject;

// Used for storing object to preferences.
- (NSDictionary *)dictionaryForObject;

@end


@interface StringTest (ProtectedMethods)

// Helper methods for storing and restoring objects from preferences. These
// are meant to be used and overridden by subclasses, and should not be 
// called directly.
- (id) initWithPropertiesFromDictionary:(NSDictionary *)dict;
- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict;

@end // @interface StringTest (ProtectedMethods)
