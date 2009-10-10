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
  
  NSMutableArray  *unboundTests;
  
  ProgressTracker  *progressTracker;
  TreeBalancer  *treeBalancer;
  ObjectPool  *dirsArrayPool;
  ObjectPool  *filesArrayPool;
}

- (id) init;
- (id) initWithFileItemTestRepository:(FileItemTestRepository *)repository;

/* Reads the tree from a file in scan dump format. Returns the annotated tree
 * context when succesful. The tree can then later be retrieved using
 * -annotatedTreeContext. Returns nil if reading is aborted, or if there is
 * an error. In the latter case, the error can be retrieved using -error.
 */
- (AnnotatedTreeContext *) readTreeFromFile: (NSString *)path;

/* Aborts reading (when it is carried out in a different execution thread). 
 */
- (void) abort;

/* Returns YES iff the reading task was aborted externally (i.e. using -abort).
 */
- (BOOL) aborted;

/* Returns the tree that was read.
 */
- (AnnotatedTreeContext *)annotatedTreeContext;

/* Returns details of the error iff there was an error when carrying out the 
 * reading task.
 */
- (NSError *) error;

/* Returns the names of any unbound filter tests, i.e. tests that could not
 * be found in the test repository.
 */
- (NSArray *) unboundFilterTests;

/* Returns a dictionary containing information about the progress of the
 * ongoing tree-reading task.
 *
 * It can safely be invoked from a different thread than the one that invoked
 * -writeTree:toFile: (and not doing so would actually be quite silly).
 */
- (NSDictionary *) progressInfo;

@end
