#import <Cocoa/Cocoa.h>

#import "FileItemHashing.h"


@protocol FileItemHashingScheme;

/* Base class for file item hashing implementations that maintain state, which
 * are therefore not thread-safe.
 */
@interface StatefulFileItemHashing : NSObject <FileItemHashing> {

  NSObject <FileItemHashingScheme>  *scheme;

}

- (id) initWithFileItemHashingScheme: 
                                  (NSObject <FileItemHashingScheme> *)scheme;

@end
