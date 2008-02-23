#import <Cocoa/Cocoa.h>


@protocol FileItemHashingScheme;
@protocol FileItemTest;


// Settings for ItemTreeDrawer objects. The settings are immutable, to 
// facilitate use in multi-threading context. 
@interface ItemTreeDrawerSettings : NSObject {
  NSColorList  *colorPalette;
  NSObject <FileItemHashingScheme>  *colorMapping;
  NSObject <FileItemTest>  *fileItemMask;
}

// Creates default settings.
- (id) init;

- (id) initWithColorMapping: (NSObject <FileItemHashingScheme> *)colorMapping
         colorPalette: (NSColorList *)colorPalette
         fileItemMask: (NSObject <FileItemTest> *)fileItemMask;

- (id) copyWithColorPalette: (NSColorList *)colorPalette;
- (id) copyWithColorMapping: (NSObject <FileItemHashingScheme> *)colorMapping;
- (id) copyWithFileItemMask: (NSObject <FileItemTest> *)fileItemMask;

- (NSColorList *)colorPalette;
- (NSObject <FileItemHashingScheme> *)colorMapping;
- (NSObject <FileItemTest> *)fileItemMask;

@end
