#import "DirectoryViewControlSettings.h"


@implementation DirectoryViewControlSettings

- (id) init {
  return [self initWithHashingKey:nil colorPaletteKey:nil mask:nil 
                 maskEnabled:NO];
}

- (id) initWithHashingKey: (NSString *)hashingKeyVal 
         colorPaletteKey: (NSString *)colorPaletteKeyVal
         mask: (NSObject <FileItemTest> *)maskVal
         maskEnabled: (BOOL) maskEnabledVal {
  if (self = [super init]) {
    hashingKey = [hashingKeyVal retain];
    colorPaletteKey = [colorPaletteKeyVal retain];
    mask = [maskVal retain];
    maskEnabled = maskEnabledVal;
  }
  
  return self;
}

- (void) dealloc {
  [hashingKey release];
  [colorPaletteKey release];
  [mask release];

  [super dealloc];
}


- (NSString*) fileItemHashingKey {
  return hashingKey;
}

- (NSString*) colorPaletteKey {
  return colorPaletteKey;
}


- (NSObject <FileItemTest>*) fileItemMask {
  return mask;
}

- (BOOL) fileItemMaskEnabled {
  return maskEnabled;
}

@end
