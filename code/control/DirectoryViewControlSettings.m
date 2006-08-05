#import "DirectoryViewControlSettings.h"


@implementation DirectoryViewControlSettings

- (id) init {
  return [self initWithHashingKey:nil mask:nil maskEnabled:NO];
}

- (id) initWithHashingKey: (NSString *)key 
         mask: (NSObject <FileItemTest> *)maskVal
         maskEnabled: (BOOL) maskEnabledVal {
  if (self = [super init]) {
    hashingKey = [key retain];
    mask = [maskVal retain];
    maskEnabled = maskEnabledVal;
  }
  
  return self;
}

- (void) dealloc {
  [hashingKey release];
  [mask release];

  [super dealloc];
}


- (NSString*) fileItemHashingKey {
  return hashingKey;
}


- (NSObject <FileItemTest>*) fileItemMask {
  return mask;
}

- (BOOL) fileItemMaskEnabled {
  return maskEnabled;
}

@end
