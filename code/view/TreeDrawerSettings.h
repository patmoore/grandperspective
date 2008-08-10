#import <Cocoa/Cocoa.h>


@protocol FileItemMapping;
@protocol FileItemTest;


/* Settings for TreeDrawer objects. The settings are immutable, to 
 * facilitate use in multi-threading context. 
 */
@interface TreeDrawerSettings : NSObject {
  NSColorList  *colorPalette;
  NSObject <FileItemMapping>  *colorMapper;
  NSObject <FileItemTest>  *fileItemMask;
  BOOL  showPackageContents;
}

// Creates default settings.
- (id) init;

- (id) initWithColorMapper: (NSObject <FileItemMapping> *)colorMapper
         colorPalette: (NSColorList *)colorPalette
         fileItemMask: (NSObject <FileItemTest> *)fileItemMask
         showPackageContents: (BOOL)showPackageContents;

- (id) copyWithColorPalette: (NSColorList *)colorPalette;
- (id) copyWithColorMapper: (NSObject <FileItemMapping> *)colorMapper;
- (id) copyWithFileItemMask: (NSObject <FileItemTest> *)fileItemMask;
- (id) copyWithShowPackageContents: (BOOL) showPackageContents;

- (NSColorList *)colorPalette;
- (NSObject <FileItemMapping> *)colorMapper;
- (NSObject <FileItemTest> *)fileItemMask;
- (BOOL) showPackageContents;

@end
