#import "StringBasedFileItemTest.h"

#import "StringTest.h"

@interface StringBasedFileItemTest (PrivateMethods)

// Not implemented. Needs to be provided by subclass.
- (NSString*) subjectDescription;

@end


@implementation StringBasedFileItemTest 

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


- (NSString*) description {
  return [stringTest descriptionWithSubject:[self subjectDescription]];
}

@end
