#import "NotItemTest.h"


@implementation NotItemTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithSubItemTest: instead.");
}

- (id) initWithSubItemTest:(NSObject<FileItemTest> *)subItemTestVal {
  if (self = [super init]) {
    subItemTest = [subItemTestVal retain];
  }

  return self;
}

- (void) dealloc {
  [subItemTest release];
  
  [super dealloc];
}

- (NSObject <FileItemTest> *) subItemTest {
  return subItemTest;
}

- (BOOL) testFileItem:(FileItem*)item {
  return ! [subItemTest testFileItem:item];
}

- (NSString*) description {
  NSString  *fmt =
    NSLocalizedStringFromTable( @"not (%@)" , @"tests", 
                                @"NOT-test with 1: sub test" );

  return [NSString stringWithFormat: fmt, [subItemTest description]];
}

@end
