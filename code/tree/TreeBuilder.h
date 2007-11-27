#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class FileItem;
@class DirectoryItem;


extern NSString  *LogicalFileSize;
extern NSString  *PhysicalFileSize;


@interface TreeBuilder : NSObject {

  NSString  *fileSizeMeasure;
  BOOL  useLogicalFileSize;
  
  BOOL  abort;
  TreeBalancer  *treeBalancer;
}

- (id) init;

- (void) abort;

- (NSString *) fileSizeMeasure;
- (void) setFileSizeMeasure: (NSString *)measure;

- (DirectoryItem *) buildVolumeTreeForPath: (NSString *)path;

// First helper method for creating a new volume tree. Next, the caller should
// set the contents for the scan tree, and subsequently invoke 
// finaliseVolumeTreeForScanTree:volumeSize:freeSpace:
//
// Note: The above all has to happen before the active autorelease pool is
// emptied. The object that is returned has references to other objects that
// it does not own (and therefore does not retain). 
+ (DirectoryItem *) scanTreeWithPath: (NSString *)relativePath
                      volumePath: (NSString *)pathToVolume;

// Second helper method for creating a new volume tree. It should be invoked
// with a scan tree created by scanTreeWithPath:volumePath.
+ (DirectoryItem *) finaliseVolumeTreeForScanTree: (DirectoryItem *)scanTree
                      volumeSize: (unsigned long long) volumeSize 
                      freeSpace: (unsigned long long) freeSpace;

+ (unsigned long long) freeSpaceOfVolume: (DirectoryItem *)root;
+ (DirectoryItem *) scanTreeOfVolume: (DirectoryItem *)root;

// TODO: Remove once ItemPathModel includes a "volumeTree" method.
+ (DirectoryItem *) volumeOfFileItem: (FileItem *)item;

@end
