#import <Cocoa/Cocoa.h>

#import "FileItemMapping.h"


@protocol FileItemMappingScheme;

/* Base class for file item mapping implementations that maintain state, which
 * are therefore not thread-safe.
 */
@interface StatefulFileItemMapping : NSObject <FileItemMapping> {

  NSObject <FileItemMappingScheme>  *scheme;

}

- (id) initWithFileItemMappingScheme: 
                                  (NSObject <FileItemMappingScheme> *)scheme;

@end
