#import "StatelessFileItemHashing.h"

@implementation StatelessFileItemHashing

- (NSObject <FileItemHashing> *) fileItemHashing {
  return self;
}

- (NSObject <FileItemHashingScheme> *) fileItemHashingScheme {
  return self;
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
