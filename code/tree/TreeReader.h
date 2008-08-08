#import <Cocoa/Cocoa.h>


@class TreeContext;

@interface TreeReader : NSObject {

  NSXMLParser  *parser;
  TreeContext  *tree;

  BOOL  abort;
  BOOL  error;

}


- (TreeContext *) readTreeFromFile: (NSString *)path;

/* Aborts reading (when it is carried out in a different execution thread). 
 */
- (void) abort;

@end
