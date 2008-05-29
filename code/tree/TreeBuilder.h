#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class UniformTypeInventory;
@class FileItem;
@class DirectoryItem;
@class TreeContext;
@class FileItemPathStringCache;
@protocol FileItemTest;


extern NSString  *LogicalFileSize;
extern NSString  *PhysicalFileSize;


@interface TreeBuilder : NSObject {

  NSString  *fileSizeMeasure;
  BOOL  useLogicalFileSize;
  
  NSObject <FileItemTest>  *filterTest;
  
  BOOL  abort;
  TreeBalancer  *treeBalancer;
  UniformTypeInventory  *typeInventory;
  
  // Contains the file numbers of the hard linked files that have been 
  // encountered so far. If a file with a same number is encountered once
  // more, it is ignored. 
  NSMutableSet  *hardLinkedFileNumbers;
  
  // Cache used by filterTest
  FileItemPathStringCache  *fileItemPathStringCache;
  
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

- (void) abort;

- (NSString *) fileSizeMeasure;
- (void) setFileSizeMeasure: (NSString *)measure;

- (NSObject <FileItemTest> *) filterTest;
- (void) setFilterTest: (NSObject <FileItemTest> *)test;

- (TreeContext *) buildTreeForPath: (NSString *)path;

@end
