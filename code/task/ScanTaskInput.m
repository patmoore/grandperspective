#import "ScanTaskInput.h"


@implementation ScanTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithDirectoryName:fileSizeType: instead");
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeType: (int)fileSizeTypeVal {
  if (self = [super init]) {
    dirName = [name retain];
    fileSizeType = fileSizeTypeVal;
  }
  return self;
}

- (void) dealloc {
  [dirName release];
  
  [super dealloc];
}


- (NSString*) directoryName {
  return dirName;
}

- (int) fileSizeType {
  return fileSizeType;
}

@end
