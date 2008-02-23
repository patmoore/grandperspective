#import "StatelessFileItemHashing.h"

@implementation StatelessFileItemHashing

- (NSObject <FileItemHashing> *) fileItemHashing {
  return self;
}

- (NSObject <FileItemHashingScheme> *) fileItemHashingScheme {
  return self;
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
