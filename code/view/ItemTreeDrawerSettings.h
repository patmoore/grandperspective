#import <Cocoa/Cocoa.h>


@class ItemTreeDrawer;
@class FileItemHashing;
@protocol FileItemTest;


// Settings for ItemTreeDrawer objects. The settings are immutable, to 
// facilitate use in multi-threading context. 
@interface ItemTreeDrawerSettings : NSObject {
  FileItemHashing  *colorMapping;
  NSColorList  *colorPalette;
  NSObject<FileItemTest>  *fileItemMask;
}

// Creates default settings.
- (id) init;

- (id) initWithColorMapping: (FileItemHashing *)colorMapping
         colorPalette: (NSColorList *)colorPalette
         fileItemMask: (NSObject<FileItemTest> *)fileItemMask;

- (id) copyWithColorMapping: (FileItemHashing *)colorMapping;
- (id) copyWithColorPalette: (NSColorList *)colorPalette;
- (id) copyWithFileItemMask: (NSObject<FileItemTest> *)fileItemMask;

- (FileItemHashing *)colorMapping;
- (NSColorList *)colorPalette;
- (NSObject <FileItemTest> *)fileItemMask;

@end
