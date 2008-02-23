#import "StatefulFileItemHashing.h"


@implementation StatefulFileItemHashing

- (id) initWithFileItemHashingScheme: 
                                (NSObject <FileItemHashingScheme> *)schemeVal {
  if (self = [super init]) {
    scheme = [schemeVal retain];
  } 
  
  return self;
}

- (void) dealloc {
  [scheme release];

  [super dealloc];
}


- (NSObject <FileItemHashingScheme> *) fileItemHashingScheme {
  return scheme;
}

- (int) hashForFileItem: (PlainFileItem *)item depth: (int) depth {
  return 0;
}

- (BOOL) canProvideLegend {
  return NO;
}

- (NSString *) descriptionForHash: (int) hash {
  return nil;
}

@end
