#import <Cocoa/Cocoa.h>

#import "FileItem.h"

extern NSString  *LogicalFileSize;
extern NSString  *PhysicalFileSize;


@class FilteredTreeGuide;
@class TreeBalancer;
@class UniformTypeInventory;
@class FileItem;
@class FilterSet;
@class DirectoryItem;
@class TreeContext;
@class ProgressTracker;


/* Constructs trees for folders by (recursively) scanning the folder's 
 * contents.
 */
@interface TreeBuilder : NSObject {

  FilterSet  *filterSet;

  NSString  *fileSizeMeasure;
  ITEM_SIZE  (*fileSizeMeasureFunction) (FSCatalogInfo *);
  
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
  
  BOOL  debugLogEnabled;
}

+ (NSArray *) fileSizeMeasureNames;

+ (BOOL) pathIsDirectory: (NSString *)path;

- (id) init;
- (id) initWithFilterSet:(FilterSet *)filterSet;

- (BOOL) packagesAsFiles;
- (void) setPackagesAsFiles: (BOOL) flag;

- (NSString *) fileSizeMeasure;
- (void) setFileSizeMeasure: (NSString *)measure;

/* Construct the tree for the given folder.
 */
- (TreeContext *) buildTreeForPath: (NSString *)path;

- (void) abort;

/* Returns a dictionary containing information about the progress of the
 * ongoing tree-building task.
 *
 * It can safely be invoked from a different thread than the one that invoked
 * -buildTreeForPath: (and not doing so would actually be quite silly).
 */
- (NSDictionary *) progressInfo;

@end
