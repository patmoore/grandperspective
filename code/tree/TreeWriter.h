#import <Cocoa/Cocoa.h>


@class TreeContext;

@interface TreeWriter : NSObject {

  FILE  *file;
  
  void  *dataBuffer;
  unsigned  dataBufferPos;
  
  BOOL  abort;

}

- (BOOL) writeTree: (TreeContext *)tree toFile: (NSString *)filename;

/* Aborts writing (when it is carried out in a different execution thread). 
 */
- (void) abort;

@end
