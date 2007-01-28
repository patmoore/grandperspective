#import "ScanTaskInput.h"


@implementation ScanTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithDirectoryName:fileSizeMeasure: instead");
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeMeasure: (int) measure {
  if (self = [super init]) {
    dirName = [name retain];
    fileSizeMeasure = measure;
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

- (int) fileSizeMeasure {
  return fileSizeMeasure;
}

@end
