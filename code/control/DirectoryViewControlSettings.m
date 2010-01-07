#import "DirectoryViewControlSettings.h"

#import "PreferencesPanelControl.h"

@implementation DirectoryViewControlSettings

- (id) init {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  return 
    [self initWithColorMappingKey:
              [userDefaults stringForKey: DefaultColorMappingKey]
            colorPaletteKey: 
              [userDefaults stringForKey: DefaultColorPaletteKey] 
            maskName: [userDefaults stringForKey: DefaultFilterName]
            maskEnabled: NO 
            showEntireVolume: NO 
            showPackageContents: 
              [[userDefaults objectForKey: ShowPackageContentsByDefaultKey] 
                  boolValue] 
            unzoomedViewSize:
              NSMakeSize([userDefaults floatForKey: DefaultViewWindowWidth],
                         [userDefaults floatForKey: DefaultViewWindowHeight]) 
            ];
}

- (id) initWithColorMappingKey:(NSString *)colorMappingKeyVal 
         colorPaletteKey:(NSString *)colorPaletteKeyVal
         maskName:(NSString *)maskNameVal
         maskEnabled:(BOOL) maskEnabledVal 
         showEntireVolume:(BOOL) showEntireVolumeVal
         showPackageContents:(BOOL) showPackageContentsVal
         unzoomedViewSize:(NSSize) unzoomedViewSizeVal {
  if (self = [super init]) {
    colorMappingKey = [colorMappingKeyVal retain];
    colorPaletteKey = [colorPaletteKeyVal retain];
    maskName = [maskNameVal retain];
    maskEnabled = maskEnabledVal;
    showEntireVolume = showEntireVolumeVal;
    showPackageContents = showPackageContentsVal;
    unzoomedViewSize = unzoomedViewSizeVal;
  }
  
  return self;
}

- (void) dealloc {
  [colorMappingKey release];
  [colorPaletteKey release];
  [maskName release];

  [super dealloc];
}


- (NSString *)colorMappingKey {
  return colorMappingKey;
}

- (void) setColorMappingKey:(NSString *)key {
  if (key != colorMappingKey) {
    [colorMappingKey release];
    colorMappingKey = [key retain];
  }
}


- (NSString *)colorPaletteKey {
  return colorPaletteKey;
}
- (void) setColorPaletteKey:(NSString *)key {
  if (key != colorPaletteKey) {
    [colorPaletteKey release];
    colorPaletteKey = [key retain];
  }
}


- (NSString *)maskName {
  return maskName;
}

- (void) setMaskName:(NSString *)maskNameVal {
  if (maskNameVal != maskName) {
    [maskName release];
    maskName = [maskNameVal retain];
  }
}


- (BOOL) fileItemMaskEnabled {
  return maskEnabled;
}

- (void) setFileItemMaskEnabled:(BOOL) flag {
  maskEnabled = flag;
}


- (BOOL) showEntireVolume {
  return showEntireVolume;
}

- (void) setShowEntireVolume:(BOOL) flag {
  showEntireVolume = flag;
}


- (BOOL) showPackageContents {
  return showPackageContents;
}

- (void) setShowPackageContents:(BOOL) flag {
  showPackageContents = flag;
}


- (NSSize) unzoomedViewSize {
  return unzoomedViewSize;
}

- (void) setunzoomedViewSize:(NSSize) size {
  unzoomedViewSize = size;
}

@end
