#import "FileItemHashing.h"

@implementation FileItemHashing

- (int) hashForFileItem:(PlainFileItem*)item depth:(int)depth {
  return 0;
}

- (BOOL) canProvideLegend {
  return NO;
}

- (NSString *) descriptionForHash: (int)hash {
  return nil;
}

@end
