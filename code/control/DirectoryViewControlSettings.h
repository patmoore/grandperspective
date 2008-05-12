#import <Cocoa/Cocoa.h>


@protocol FileItemTest;


@interface DirectoryViewControlSettings : NSObject {
  NSString  *colorMappingKey;
  NSString  *colorPaletteKey;
  NSObject <FileItemTest>  *mask;
  BOOL  maskEnabled;
  BOOL  showEntireVolume;
  BOOL  showPackageContents;
}

- (id) initWithColorMappingKey: (NSString *)colorMappingKey 
         colorPaletteKey: (NSString *)colorPaletteKey
         mask: (NSObject <FileItemTest> *)mask
         maskEnabled: (BOOL) maskEnabled
         showEntireVolume: (BOOL) showEntireVolume
         showPackageContents: (BOOL) showPackageContents;

- (NSString*) colorMappingKey;
- (void) setColorMappingKey: (NSString *)key;

- (NSString*) colorPaletteKey;
- (void) setColorPaletteKey: (NSString *)key;

- (NSObject <FileItemTest>*) fileItemMask;
- (void) setFileItemMask: (NSObject <FileItemTest> *)mask;

- (BOOL) fileItemMaskEnabled;
- (void) setFileItemMaskEnabled: (BOOL)flag;

- (BOOL) showEntireVolume;
- (void) setShowEntireVolume: (BOOL)flag;

- (BOOL) showPackageContents;
- (void) setShowPackageContents: (BOOL)flag;

@end
