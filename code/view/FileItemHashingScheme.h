#import <Cocoa/Cocoa.h>

@protocol FileItemHashing;

/* A file item hashing scheme. It represents a particular algorithm for 
 * deriving a hash value from a file item.
 *
 * File item hashing schemes can safely be used from multiple threads.
 */
@protocol FileItemHashingScheme

/* Returns a file item hashing instance that implements the scheme. When the
 * implementation is not thread-safe, a new instance is returned for each
 * invocation. This way, in a multi-threading context, each thread can have
 * its own instance which it can safely use. 
 */
- (NSObject <FileItemHashing> *) fileItemHashing;

@end
