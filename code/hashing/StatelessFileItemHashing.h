#import <Cocoa/Cocoa.h>

#import "FileItemHashing.h"
#import "FileItemHashingScheme.h"

/* Base class for file item hashing implementations that do not maintain any
 * state (which are therefore thread-safe). 
 *
 * Given that the implementation is stateless, the corresponding file item
 * hashing scheme can always return the same file item hashing instance, which
 * therefore can also represent the scheme.
 */
@interface StatelessFileItemHashing : 
             NSObject <FileItemHashingScheme, FileItemHashing> {
}

@end