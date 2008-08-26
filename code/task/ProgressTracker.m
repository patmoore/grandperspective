#import "ProgressTracker.h"

#import "DirectoryItem.h"


NSString  *NumFoldersProcessedKey = @"numFoldersProcessed";
NSString  *NumFoldersSkippedKey = @"numFoldersSkipped";
NSString  *CurrentFolderPathKey = @"currentFolderPath";


@implementation ProgressTracker

- (id) init {
  if (self = [super init]) {
    mutex = [[NSLock alloc] init];
    directoryStack = [[NSMutableArray alloc] initWithCapacity: 16];
  }

  return self;
}

- (void) dealloc {
  [mutex release];
  [directoryStack release];
  
  [super dealloc];

}

- (void) startingTask {
  // NSLog(@"startingTask");

  [mutex lock];
  numFoldersProcessed = 0;
  numFoldersSkipped = 0;
  [directoryStack removeAllObjects];
  [mutex unlock];
}

- (void) finishedTask {
  // NSLog(@"finishedTask");

  [mutex lock];
  [directoryStack removeAllObjects];
  [mutex unlock];
}


- (void) processingFolder: (DirectoryItem *)dirItem {
  [mutex lock];

  if ([directoryStack count] == 0) {
    // Find the root of the tree
    DirectoryItem  *root = dirItem;
    DirectoryItem  *parent = nil;
    while ((parent = [root parentDirectory]) != nil) {
      root = parent;
    }

    if (root != dirItem) {
      // Add the root of the tree to the stack. This ensures that -path can be
      // called for any FileItem in the stack, even after the tree has been 
      // released externally (e.g. because the task constructing it has been 
      // aborted).
      [directoryStack addObject: root];
    }
  }

  [directoryStack addObject: dirItem];
  [mutex unlock];
}

- (void) processedFolder: (DirectoryItem *)dirItem {
  [mutex lock];
  NSAssert([directoryStack lastObject] == dirItem, @"Inconsistent stack.");
  [directoryStack removeLastObject];
  numFoldersProcessed++;
  [mutex unlock];
}

- (void) skippedFolder: (DirectoryItem *)dirItem {
  [mutex lock];
  numFoldersSkipped++;
  [mutex unlock];
}


- (NSDictionary *)progressInfo {
  NSDictionary  *dict;

  [mutex lock];
  dict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt: numFoldersProcessed],
            NumFoldersProcessedKey,
            [NSNumber numberWithInt: numFoldersSkipped],
            NumFoldersSkippedKey,
            [[directoryStack lastObject] path],
            CurrentFolderPathKey,
            nil];
  [mutex unlock];

  return dict;
}

@end // @implementation ProgressTracker

