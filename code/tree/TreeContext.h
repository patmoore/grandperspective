#import <Cocoa/Cocoa.h>

extern NSString  *FreeSpace;
extern NSString  *UsedSpace;
extern NSString  *MiscUsedSpace;
extern NSString  *FreedSpace;

extern NSString  *FileItemDeletedEvent;

@class FileItem;
@class FileItemFilterSet;
@class DirectoryItem;
@class ItemPathModelView;


@interface TreeContext : NSObject {
  unsigned long long  volumeSize;
  unsigned long long  freeSpace;
  unsigned long long  freedSpace;
  unsigned long long  freedFiles;

  DirectoryItem  *volumeTree;
  DirectoryItem  *usedSpaceItem;
  DirectoryItem  *scanTree;

  NSDate  *scanTime;
  NSString  *fileSizeMeasure;
  
  FileItemFilterSet  *filterSet;
  
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


/* Creates a new tree context, with the scan time set to "now".
 */
- (id) initWithVolumePath: (NSString *)volumePath
         fileSizeMeasure: (NSString *)fileSizeMeasure
         volumeSize: (unsigned long long) volumeSize 
         freeSpace: (unsigned long long) freeSpace
         filterSet: (FileItemFilterSet *)filterSet;
         
/* Creates a new tree context. 
 *
 * Note: The returned object is not yet fully ready. A volume-tree skeleton
 * is created, but still needs to be finalised. The scanTree still needs
 * to be set using -setScanTree.
 */
- (id) initWithVolumePath: (NSString *)volumePath
         fileSizeMeasure: (NSString *)fileSizeMeasure
         volumeSize: (unsigned long long) volumeSize 
         freeSpace: (unsigned long long) freeSpace
         filterSet: (FileItemFilterSet *)filterSet
         scanTime: (NSDate *)scanTime;


/* Sets the scan tree. This finalises the volume tree. The parent of the scan
 * tree should be that returned by -scanTreeParent.
 */
- (void) setScanTree: (DirectoryItem *)scanTree;

/* The parent (to be) for the scan tree.
 */
- (DirectoryItem *) scanTreeParent;


- (DirectoryItem*) volumeTree;
- (DirectoryItem*) scanTree;

/* The size of the volume (in bytes)
 */
- (unsigned long long) volumeSize;

/* The free space of the volume at the time of the scan. 
 */
- (unsigned long long) freeSpace;

/* The space that has been freed using -deleteSelectedFileItem since the scan.
 */
- (unsigned long long) freedSpace;

/* The number of freed files
 */
- (unsigned long long) freedFiles;

- (NSString*) fileSizeMeasure;

- (NSDate *) scanTime;

/* A string representation for the scan time.
 */
- (NSString *) stringForScanTime;

- (FileItemFilterSet *) filterSet;


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
