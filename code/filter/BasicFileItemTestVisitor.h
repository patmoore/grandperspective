#import <Cocoa/Cocoa.h>

#import "FileItemTestVisitor.h"


/**
 * A minimal visitor implementation. It does two things. Firstly, it 
 * implements all methods of the FileItemTestVisitor protocol (so that 
 * sub classes only need to implement the methods they are interested in).
 * Secondly, it recursively visits the item tests. To disable this behaviour
 * for a specific compound item test, simply override its "visit" method.
 */
@interface BasicFileItemTestVisitor : NSObject <FileItemTestVisitor> {

}

@end
