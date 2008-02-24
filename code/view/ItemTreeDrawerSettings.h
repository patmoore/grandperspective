#import <Cocoa/Cocoa.h>


@protocol FileItemHashing;
@protocol FileItemTest;


// Settings for ItemTreeDrawer objects. The settings are immutable, to 
// facilitate use in multi-threading context. 
@interface ItemTreeDrawerSettings : NSObject {
  NSColorList  *colorPalette;
  NSObject <FileItemHashing>  *colorMapper;
  NSObject <FileItemTest>  *fileItemMask;
}

// Creates default settings.
- (id) init;

- (id) initWithColorMapper: (NSObject <FileItemHashing> *)colorMapper
         colorPalette: (NSColorList *)colorPalette
         fileItemMask: (NSObject <FileItemTest> *)fileItemMask;

- (id) copyWithColorPalette: (NSColorList *)colorPalette;
- (id) copyWithColorMapper: (NSObject <FileItemHashing> *)colorMapper;
- (id) copyWithFileItemMask: (NSObject <FileItemTest> *)fileItemMask;

- (NSColorList *)colorPalette;
- (NSObject <FileItemHashing> *)colorMapper;
- (NSObject <FileItemTest> *)fileItemMask;

@end
