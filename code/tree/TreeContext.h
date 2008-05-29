#import <Cocoa/Cocoa.h>

extern NSString  *FreeSpace;
extern NSString  *UsedSpace;
extern NSString  *MiscUsedSpace;
extern NSString  *FreedSpace;

extern NSString  *FileItemDeletedEvent;

@protocol FileItemTest;
@class FileItem;
@class DirectoryItem;
@class ItemPathModelView;

@interface TreeContext : NSObject {
  unsigned long long  volumeSize;
  unsigned long long  freeSpace;
  unsigned long long  freedSpace;

  DirectoryItem  *volumeTree;
  DirectoryItem  *scanTree;

  NSDate  *scanTime;
  NSString  *fileSizeMeasure;
  
  NSObject <FileItemTest>  *filter;
  int  filterId;
  
  FileItem  *replacedItem;
  FileItem  *replacingItem;
  
  /* Variables used for synchronizing read/write access to the tree.
   */
  NSLock  *mutex;
  NSConditionLock  *lock;
  
  // The number of active reading threads.
  int  numReaders;
  
  // The number of threads currently waiting using "lock"
  int  numWaitingReaders;
  int  numWaitingWriters;
}


/* Creates a new tree context, without a filter and with a scan time set to 
 * "now". A volume-tree skeleton is created, but still needs to be finalised.
 *
 * Note: The returned object is not yet fully ready. The contents scanTree
 * of its scan tree need to be set, after which -postInit must be called.
 */
- (id) initWithVolumePath: (NSString *)volumePath
         scanPath: (NSString *)relativePath
         fileSizeMeasure: (NSString *)fileSizeMeasureVal
         filterTest: (NSObject <FileItemTest> *)filter
         volumeSize: (unsigned long long) volumeSize 
         freeSpace: (unsigned long long) freeSpace;

/* Creates a new tree context, based on the current one, but with an additional
 * filter applied. The filtering itself still needs to be performed. This is
 * the responsibility of the sender, after which it has to finalise the 
 * volume tree.
 *
 * Note: The returned object is not yet fully ready. The contents scanTree
 * of its scan tree need to be set, after which -postInit must be called.
 */
- (TreeContext *) contextAfterFiltering: (NSObject <FileItemTest> *)newFilter;

/* Finalises the volume tree. It should be called after the scan tree
 * contents have been set.
 */
- (void) postInit;


- (DirectoryItem*) volumeTree;
- (DirectoryItem*) scanTree;

- (unsigned long long) volumeSize;
- (unsigned long long) freeSpace;
- (unsigned long long) freedSpace;

- (NSString*) fileSizeMeasure;
- (NSDate*) scanTime;

- (NSObject <FileItemTest>*) fileItemFilter;

// A unique identifier for the filter. Returns "0" iff there is no filter.
- (int) filterIdentifier;

// Returns a localized string, based on the filter identifier.
- (NSString*) filterName;

- (void) deleteSelectedFileItem: (ItemPathModelView *)path;


/* Returns the item that is being replaced.
 *
 * It should only be called in response to a TreeItemReplacedEvent. It will
 * return "nil" otherwise.
 */
- (FileItem *) replacedFileItem;

/* Returns the item that replaces the item that is being replaced.
 *
 * It should only be called in response to a TreeItemReplacedEvent. It will
 * return "nil" otherwise.
 */
- (FileItem *) replacingFileItem;


/* Obtains a read lock on the tree. This is required before reading, e.g.
 * traversing, (parts of) the tree. There can be multiple readers active 
 * simultaneously.
 */
- (void) obtainReadLock;

- (void) releaseReadLock;

/* Obtains a write lock. This is required before modifying the tree. A write
 * lock is only given out when there are no readers. A thread should only try
 * to acquire a write lock, if it does not already own a read lock, otherwise a 
 * deadlock will result.
 *
 * Note: Although not required by the implementation of the lock, the current
 * usage is as follows. Only the main thread will make modifications (after
 * having acquired a write lock). The background threads that read the tree
 * (e.g. to draw it) always obtain read locks first. However, the main thread
 * never acquires a read lock; there is no need because writing is not done 
 * from other threads.
 */
- (void) obtainWriteLock;

- (void) releaseWriteLock;

@end
