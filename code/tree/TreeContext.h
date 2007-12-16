#import <Cocoa/Cocoa.h>

extern NSString  *FreeSpace;
extern NSString  *UsedSpace;
extern NSString  *MiscUsedSpace;
extern NSString  *FreedSpace;

extern NSString  *TreeItemReplacedEvent;

@protocol FileItemTest;
@class FileItem;
@class DirectoryItem;
@class ItemPathModel;

@interface TreeContext : NSObject {
  unsigned long long  volumeSize;
  unsigned long long  freeSpace;

  DirectoryItem  *volumeTree;
  DirectoryItem  *scanTree;

  NSDate  *scanTime;
  NSString  *fileSizeMeasure;
  
  NSObject <FileItemTest>  *filter;
  int  filterId;
  
  FileItem  *replacedItem;
  FileItem  *replacingItem;
}


// Creates a new tree context, without a filter and with a scan time set to 
// "now". A volume-tree skeleton is created, but still needs to be finalised.
//
// Note: The returned object is not yet fully ready. The contents scanTree
// of its scan tree need to be set, after which -postInit must be called.
- (id) initWithVolumePath: (NSString *)volumePath
         scanPath: (NSString *)relativePath
         fileSizeMeasure: (NSString *)fileSizeMeasureVal
         volumeSize: (unsigned long long) volumeSize 
         freeSpace: (unsigned long long) freeSpace;

// Creates a new tree context, based on the current one, but with an additional
// filter applied. The filtering itself still needs to be performed. This is
// the responsibility of the sender, after which it has to finalise the 
// volume tree.
//
// Note: The returned object is not yet fully ready. The contents scanTree
// of its scan tree need to be set, after which -postInit must be called.
- (TreeContext *) contextAfterFiltering: (NSObject <FileItemTest> *)newFilter;

// Finalises the volume tree. It should be called after the scan tree
// contents have been set.
- (void) postInit;

- (DirectoryItem*) volumeTree;
- (DirectoryItem*) scanTree;

- (unsigned long long) volumeSize;
- (unsigned long long) freeSpace;

- (NSString*) fileSizeMeasure;
- (NSDate*) scanTime;

- (NSObject <FileItemTest>*) fileItemFilter;

// A unique identifier for the filter. Returns "0" iff there is no filter.
- (int) filterIdentifier;

// Returns a localized string, based on the filter identifier.
- (NSString*) filterName;

- (void) replaceSelectedItem: (ItemPathModel *)path 
           bySpecialItemWithName: (NSString *)newName;

// These method should only be called in response to a TreeItemReplacedEvent.
// They will return "nil" otherwise.
- (FileItem *) replacedFileItem;
- (FileItem *) replacingFileItem;

@end
