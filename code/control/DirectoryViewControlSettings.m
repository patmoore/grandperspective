#import "DirectoryViewControlSettings.h"

#import "PreferencesPanelControl.h"
#import "Filter.h"

@implementation DirectoryViewControlSettings

- (id) init {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  return 
    [self initWithColorMappingKey:
              [userDefaults stringForKey: DefaultColorMappingKey]
            colorPaletteKey: 
              [userDefaults stringForKey: DefaultColorPaletteKey] 
            mask: nil 
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

- (id) initWithColorMappingKey: (NSString *)colorMappingKeyVal 
         colorPaletteKey: (NSString *)colorPaletteKeyVal
         mask: (Filter *)maskVal
         maskEnabled: (BOOL) maskEnabledVal 
         showEntireVolume: (BOOL) showEntireVolumeVal
         showPackageContents: (BOOL) showPackageContentsVal
         unzoomedViewSize: (NSSize) unzoomedViewSizeVal {
  if (self = [super init]) {
    colorMappingKey = [colorMappingKeyVal retain];
    colorPaletteKey = [colorPaletteKeyVal retain];
    mask = [maskVal retain];
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
  [mask release];

  [super dealloc];
}


- (NSString*) colorMappingKey {
  return colorMappingKey;
}

- (void) setColorMappingKey: (NSString *)key {
  if (key != colorMappingKey) {
    [colorMappingKey release];
    colorMappingKey = [key retain];
  }
}


- (NSString*) colorPaletteKey {
  return colorPaletteKey;
}
- (void) setColorPaletteKey: (NSString *)key {
  if (key != colorPaletteKey) {
    [colorPaletteKey release];
    colorPaletteKey = [key retain];
  }
}


- (Filter *) fileItemMask {
  return mask;
}

- (void) setFileItemMask:(Filter *)maskVal {
  if (maskVal != mask) {
    [mask release];
    mask = [maskVal retain];
  }
}


- (BOOL) fileItemMaskEnabled {
  return maskEnabled;
}

- (void) setFileItemMaskEnabled: (BOOL)flag {
  maskEnabled = flag;
}


- (BOOL) showEntireVolume {
  return showEntireVolume;
}

- (void) setShowEntireVolume: (BOOL)flag {
  showEntireVolume = flag;
}


- (BOOL) showPackageContents {
  return showPackageContents;
}

- (void) setShowPackageContents: (BOOL)flag {
  showPackageContents = flag;
}


- (NSSize) unzoomedViewSize {
  return unzoomedViewSize;
}

- (void) setunzoomedViewSize: (NSSize) size {
  unzoomedViewSize = size;
}

@end
