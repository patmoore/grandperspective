#import "ScanTaskInput.h"


@implementation ScanTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithDirectoryName:fileSizeMeasure: instead");
}

- (id) initWithDirectoryName: (NSString *)dirNameVal 
         fileSizeMeasure: (NSString *)fileSizeMeasureVal {
  if (self = [super init]) {
    dirName = [dirNameVal retain];
    fileSizeMeasure = [fileSizeMeasureVal retain];
  }
  return self;
}

- (void) dealloc {
  [dirName release];
  [fileSizeMeasure release];
  
  [super dealloc];
}


- (NSString *) directoryName {
  return dirName;
}

- (NSString *) fileSizeMeasure {
  return fileSizeMeasure;
}

@end
