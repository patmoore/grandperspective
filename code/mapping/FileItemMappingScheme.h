#import <Cocoa/Cocoa.h>


/* Event that is fired when there have been changes to the mapping scheme
 * that may cause one or more file items to map to a different hash value.
 */
extern NSString  *MappingSchemeChangedEvent;


@protocol FileItemMapping;

/* A file item mapping scheme. It represents a particular algorithm for 
 * mapping file items to hash values.
 *
 * File item mapping schemes can safely be used from multiple threads.
 */
@protocol FileItemMappingScheme

/* Returns a file item mapping instance that implements the scheme. When the
 * implementation is not thread-safe, a new instance is returned for each
 * invocation. This way, in a multi-threading context, each thread can have
 * its own instance which it can safely use. 
 */
- (NSObject <FileItemMapping> *) fileItemMapping;

@end
