#import <Cocoa/Cocoa.h>


@protocol FileItemMapping;
@protocol FileItemTest;


// Settings for ItemTreeDrawer objects. The settings are immutable, to 
// facilitate use in multi-threading context. 
@interface ItemTreeDrawerSettings : NSObject {
  NSColorList  *colorPalette;
  NSObject <FileItemMapping>  *colorMapper;
  NSObject <FileItemTest>  *fileItemMask;
}

// Creates default settings.
- (id) init;

- (id) initWithColorMapper: (NSObject <FileItemMapping> *)colorMapper
         colorPalette: (NSColorList *)colorPalette
         fileItemMask: (NSObject <FileItemTest> *)fileItemMask;

- (id) copyWithColorPalette: (NSColorList *)colorPalette;
- (id) copyWithColorMapper: (NSObject <FileItemMapping> *)colorMapper;
- (id) copyWithFileItemMask: (NSObject <FileItemTest> *)fileItemMask;

- (NSColorList *)colorPalette;
- (NSObject <FileItemMapping> *)colorMapper;
- (NSObject <FileItemTest> *)fileItemMask;

@end
