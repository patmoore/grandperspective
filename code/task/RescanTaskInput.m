#import "RescanTaskInput.h"

#import "TreeHistory.h"
#import "DirectoryItem.h"


@implementation RescanTaskInput

// Overrides designated initialiser
- (id) initWithDirectoryName: (NSString *)name 
         fileSizeMeasure: (NSString *)measure {
  NSAssert
    (NO, @"Use initWithOldHistory: instead");
}

- (id) initWithOldHistory: (TreeHistory *) oldHistoryVal {
  if (self = [super initWithDirectoryName: [[oldHistoryVal scanTree] name]
                      fileSizeMeasure: [oldHistoryVal fileSizeMeasure]]) {
    oldHistory = [oldHistoryVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [oldHistory release];
  
  [super dealloc];
}


- (TreeHistory *) oldHistory {
  return oldHistory;
}

@end
