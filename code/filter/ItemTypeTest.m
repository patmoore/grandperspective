#import "ItemTypeTest.h"


@implementation ItemTypeTest

- (id) initWithName:(NSString*)nameVal testForPlainFile:(BOOL)plainFileFlag {
  if (self = [super initWithName:nameVal]) {
    testForPlainFile = plainFileFlag;    
  }
  
  return self;
}

- (BOOL) testFileItem:(FileItem*)item {
  return [item isPlainFile] == testForPlainFile;
}

- (NSString*) description {
  return (testForPlainFile ? @"item is a file" : @"item is a folder");
}

@end
