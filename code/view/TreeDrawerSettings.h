#import <Cocoa/Cocoa.h>


@protocol FileItemMapping;
@class FileItemTest;


/* Settings for TreeDrawer objects. The settings are immutable, to 
 * facilitate use in multi-threading context. 
 */
@interface TreeDrawerSettings : NSObject {
  NSObject <FileItemMapping>  *colorMapper;
  NSColorList  *colorPalette;
  float  colorGradient;
  FileItemTest  *fileItemMask;
  BOOL  showPackageContents;
}

// Creates default settings.
- (id) init;

- (id) initWithColorMapper:(NSObject <FileItemMapping> *)colorMapper
         colorPalette:(NSColorList *)colorPalette
         colorGradient:(float) colorGradient
         fileItemMask:(FileItemTest *)fileItemMask
         showPackageContents:(BOOL) showPackageContents;

- (id) copyWithColorMapper:(NSObject <FileItemMapping> *)colorMapper;
- (id) copyWithColorPalette:(NSColorList *)colorPalette;
- (id) copyWithColorGradient:(float) colorGradient;
- (id) copyWithFileItemMask:(FileItemTest *)fileItemMask;
- (id) copyWithShowPackageContents:(BOOL) showPackageContents;

- (NSObject <FileItemMapping> *)colorMapper;
- (NSColorList *)colorPalette;
- (float) colorGradient;
- (FileItemTest *)fileItemMask;
- (BOOL) showPackageContents;

@end
