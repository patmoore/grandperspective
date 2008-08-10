#import <Cocoa/Cocoa.h>


extern NSString  *LogicalFileSize;
extern NSString  *PhysicalFileSize;


@class FilteredTreeGuide;
@class TreeBalancer;
@class UniformTypeInventory;
@class FileItem;
@class DirectoryItem;
@class TreeContext;
@class ProgressTracker;


/* Constructs trees for folders by (recursively) scanning the folder's 
 * contents.
 */
@interface TreeBuilder : NSObject {

  NSString  *fileSizeMeasure;
  BOOL  useLogicalFileSize;
  
  BOOL  abort;
  FilteredTreeGuide  *treeGuide;
  TreeBalancer  *treeBalancer;
  UniformTypeInventory  *typeInventory;
  
  // Contains the file numbers of the hard linked files that have been 
  // encountered so far. If a file with a same number is encountered once
  // more, it is ignored. 
  NSMutableSet  *hardLinkedFileNumbers;
  
  ProgressTracker  *progressTracker;
  
  // Temporary buffer for constructing path names
  UInt8  *pathBuffer;
  int  pathBufferLen;
  
  // Temporary buffers for getting bulk catalog data
  void  *bulkCatalogInfo;
  FSCatalogInfo  *catalogInfoArray;
  FSRef  *fileRefArray;
  HFSUniStr255   *namesArray;
}

+ (NSArray *) fileSizeMeasureNames;

- (id) init;
- (id) initWithFilteredTreeGuide: (FilteredTreeGuide *)treeGuide;

- (void) abort;

- (NSString *) fileSizeMeasure;
- (void) setFileSizeMeasure: (NSString *)measure;

/* Construct the tree for the given folder.
 */
- (TreeContext *) buildTreeForPath: (NSString *)path;

/* Returns a dictionary containing information about the progress of the
 * ongoing tree-building task.
 *
 * It can safely be invoked from a different thread than the one that invoked
 * -buildTreeForPath: (and not doing so would actually be quite silly).
 */
- (NSDictionary *) progressInfo;

@end
