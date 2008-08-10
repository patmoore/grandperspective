#import <Cocoa/Cocoa.h>


extern NSString  *NumFoldersProcessedKey;
extern NSString  *CurrentFolderPathKey;


@class TreeContext;

@interface TreeWriter : NSObject {

  FILE  *file;
  
  void  *dataBuffer;
  unsigned  dataBufferPos;
  
  BOOL  abort;
  NSError  *error;
  
  // Lock protecting the progress statistics (which can be retrieved from a
  // thread different than the one writing the tree).
  NSLock  *statsLock;
  
  // The number of folders that have been written so far.
  int  numFoldersProcessed;
   
  // The stack of directories that is currently being processed. The last
  // item is the directory that is currently being written.
  NSMutableArray  *directoryStack;
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

/* Returns YES iff the writing task was aborted externally (i.e. using -abort).
 */
- (BOOL) aborted;

/* Returns details of the error iff there was an error when carrying out the 
 * writing task.
 */
- (NSError *) error;

/* Returns a dictionary containing information about the progress of the
 * ongoing tree-writing task.
 *
 * It can safely be invoked from a different thread than the one that invoked
 * -writeTree:toFile: (and not doing so would actually be quite silly).
 */
- (NSDictionary *) treeWriterProgressInfo;

@end
