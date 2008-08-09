#import <Cocoa/Cocoa.h>


@class TreeContext;

@interface TreeReader : NSObject {

  NSXMLParser  *parser;
  TreeContext  *tree;

  BOOL  abort;
  NSError  *error;
}


- (TreeContext *) readTreeFromFile: (NSString *)path;

/* Aborts reading (when it is carried out in a different execution thread). 
 */
- (void) abort;

/* Returns YES iff the reading task was aborted externally (i.e. using -abort).
 */
- (BOOL) aborted;

/* Returns details of the error iff there was an error when carrying out the 
 * reading task.
 */
- (NSError *) error;

@end
