#import "ItemNameTest.h"


@implementation ItemNameTest 

- (id) initWithName:(NSString*)nameVal {
  NSAssert(NO, @"Use initWithName:stringTest instead.");
}

- (id) initWithName:(NSString*)nameVal
         stringTest:(NSObject <StringTest>*)stringTestVal {
  if (self = [super initWithName:nameVal]) {
    stringTest = [stringTestVal retain];
  }
  return self;
}

- (void) dealloc {
  [stringTest release];
  
  [super dealloc];
}

- (BOOL) testFileItem:(FileItem*)item {
  return [stringTest testString:[item name]];
}

- (NSString*) description {
  return [stringTest descriptionWithSubject:@"name"];
}

@end