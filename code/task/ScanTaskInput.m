#import "ScanTaskInput.h"


@implementation ScanTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithDirectoryName:fileSizeType: instead");
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeType: (NSString *)fileSizeTypeVal {
  if (self = [super init]) {
    dirName = [name retain];
    fileSizeType = [fileSizeTypeVal retain];
  }
  return self;
}

- (void) dealloc {
  [dirName release];
  [fileSizeType release];
  
  [super dealloc];
}


- (NSString*) directoryName {
  return dirName;
}

- (NSString*) fileSizeType {
  return fileSizeType;
}

@end
