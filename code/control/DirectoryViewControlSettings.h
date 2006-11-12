#import <Cocoa/Cocoa.h>


@protocol FileItemTest;


@interface DirectoryViewControlSettings : NSObject {
  NSString  *colorMappingKey;
  NSString  *colorPaletteKey;
  NSObject <FileItemTest>  *mask;
  BOOL  maskEnabled;
}

- (id) initWithColorMappingKey: (NSString *)colorMappingKey 
         colorPaletteKey: (NSString *)colorPaletteKey
         mask: (NSObject <FileItemTest> *)mask
         maskEnabled: (BOOL) maskEnabled;

- (NSString*) colorMappingKey;
- (NSString*) colorPaletteKey;

- (NSObject <FileItemTest>*) fileItemMask;
- (BOOL) fileItemMaskEnabled;

@end
