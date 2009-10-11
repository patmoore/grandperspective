#import <Cocoa/Cocoa.h>

#import "FileItemMapping.h"
#import "FileItemMappingScheme.h"

/* Base class for file item mapping implementations that do not maintain any
 * state (which are therefore thread-safe). 
 *
 * Given that the implementation is stateless, the corresponding file item
 * mapping scheme can always return the same file item mapping instance, which
 * therefore can also represent the scheme.
 */
@interface StatelessFileItemMapping : 
             NSObject <FileItemMappingScheme, FileItemMapping> {
}

@end
