#import "DirectoryViewControlSettings.h"


@implementation DirectoryViewControlSettings

- (id) init {
  return [self initWithColorMappingKey: nil colorPaletteKey: nil mask: nil 
                 maskEnabled: NO];
}

- (id) initWithColorMappingKey: (NSString *)colorMappingKeyVal 
         colorPaletteKey: (NSString *)colorPaletteKeyVal
         mask: (NSObject <FileItemTest> *)maskVal
         maskEnabled: (BOOL) maskEnabledVal {
  if (self = [super init]) {
    colorMappingKey = [colorMappingKeyVal retain];
    colorPaletteKey = [colorPaletteKeyVal retain];
    mask = [maskVal retain];
    maskEnabled = maskEnabledVal;
  }
  
  return self;
}

- (void) dealloc {
  [colorMappingKey release];
  [colorPaletteKey release];
  [mask release];

  [super dealloc];
}


- (NSString*) colorMappingKey {
  return colorMappingKey;
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
