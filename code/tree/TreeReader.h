#import <Cocoa/Cocoa.h>

@class FileItemTestRepository;
@class AnnotatedTreeContext;
@class TreeBalancer;
@class ProgressTracker;
@class ObjectPool;

@interface TreeReader : NSObject {

  FileItemTestRepository  *testRepository;

  NSXMLParser  *parser;
  AnnotatedTreeContext  *tree;

  BOOL  abort;
  NSError  *error;
  
  ProgressTracker  *progressTracker;
  TreeBalancer  *treeBalancer;
  ObjectPool  *dirsArrayPool;
  ObjectPool  *filesArrayPool;
}

- (id) init;
- (id) initWithFileItemTestRepository:(FileItemTestRepository *)repository;

- (AnnotatedTreeContext *) readTreeFromFile: (NSString *)path;

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

/* Returns a dictionary containing information about the progress of the
 * ongoing tree-reading task.
 *
 * It can safely be invoked from a different thread than the one that invoked
 * -writeTree:toFile: (and not doing so would actually be quite silly).
 */
- (NSDictionary *) progressInfo;

@end
