#import "RescanTaskInput.h"

#import "TreeHistory.h"
#import "DirectoryItem.h"


@implementation RescanTaskInput

// Overrides designated initialiser
- (id) initWithDirectoryName: (NSString *)name 
         fileSizeMeasure: (NSString *)measure {
  NSAssert(NO, @"Use initWithOldContext: instead");
}

- (id) initWithOldContext: (TreeContext *)oldContextVal {
  NSString  *scanTreePath = [[oldContextVal scanTree] stringForFileItemPath];
  if (self = [super initWithDirectoryName: scanTreePath
                      fileSizeMeasure: [oldContextVal fileSizeMeasure]]) {
    oldContext = [oldContextVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [oldContext release];
  
  [super dealloc];
}


- (TreeContext *) oldContext {
  return oldContext;
}

@end
