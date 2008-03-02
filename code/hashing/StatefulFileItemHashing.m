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


- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  return 0;
}

- (int) hashForFileItem: (PlainFileItem *)item inTree: (FileItem *)treeRoot {
  // By default assuming that "depth" is not used in the hash calculation.
  // If it is, this method needs to be overridden.
  return [self hashForFileItem: item atDepth: -1];
}


- (BOOL) canProvideLegend {
  return NO;
}

@end
