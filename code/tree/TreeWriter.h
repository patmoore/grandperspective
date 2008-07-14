#import <Cocoa/Cocoa.h>


@class TreeContext;

@interface TreeWriter : NSObject {

  FILE  *file;
  
  void  *dataBuffer;
  unsigned  dataBufferPos;
  
  BOOL  abort;
  BOOL  error;
}

/* Writes the tree to file (in XML format). Returns YES if the operation
 * completed successfully. Returns NO if an error occurred, or if the
 * operation has been aborted. In the latter case, however, the file will
 * still be valid. It simply will not contain all files/folders in the tree.
 */
- (BOOL) writeTree: (TreeContext *)tree toFile: (NSString *)path;

/* Aborts writing (when it is carried out in a different execution thread). 
 */
- (void) abort;

@end
