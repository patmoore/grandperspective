#import <Cocoa/Cocoa.h>


@class FilteredTreeGuide;
@class TreeBalancer;
@class UniformTypeInventory;
@class FileItem;
@class DirectoryItem;
@class TreeContext;


extern NSString  *LogicalFileSize;
extern NSString  *PhysicalFileSize;

// Keys used in the dictionary returned by -treeBuilderProgressInfo
extern NSString  *NumBuildableFoldersKey;
extern NSString  *NumFoldersBuiltKey;
extern NSString  *NumInaccessibleFoldersKey;
extern NSString  *CurrentFolderPathKey;

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
  
  // Lock protecting the progress statistics.
  NSLock  *statsLock;
  
  // The (current) total number of folders that need to be build. It includes
  // folders that have been built already. This count goes up when new folders 
  // are being encountered while the tree is being built. It is always larger
  // than "numFoldersBuilt", except when the tree has been completely built,
  // in which case both numbers should be equal.
  int  numBuildableFolders;
  
  // The number of folders that have been constructed so far. This includes
  // folders that were subsequently discarded because they did not pass the
  // filter test. It also includes folders whose contents could not be read.
  int  numFoldersBuilt;
  
  // The number of folders whose contents could not be read due to 
  // insufficient permissions.
  int  numInaccessibleFolders;
  
  // The directory that is currently being scanned.
  DirectoryItem  *currentDirectory;
  
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
- (NSDictionary *) treeBuilderProgressInfo;

@end
