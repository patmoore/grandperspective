#import <Cocoa/Cocoa.h>


@protocol StringTest

- (BOOL) testString:(NSString*)string;

- (NSString*) descriptionWithSubject:(NSString*)subject;

// Used for storing object to preferences.
- (NSDictionary *) dictionaryForObject;

@end
