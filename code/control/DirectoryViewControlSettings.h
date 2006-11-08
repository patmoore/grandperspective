#import <Cocoa/Cocoa.h>


@protocol FileItemTest;


@interface DirectoryViewControlSettings : NSObject {
  NSString  *hashingKey;
  NSString  *colorPaletteKey;
  NSObject <FileItemTest>  *mask;
  BOOL  maskEnabled;
}

- (id) initWithHashingKey: (NSString *)hashingKey 
         colorPaletteKey: (NSString *)colorPaletteKey
         mask: (NSObject <FileItemTest> *)mask
         maskEnabled: (BOOL) maskEnabled;

- (NSString*) fileItemHashingKey;
- (NSString*) colorPaletteKey;

- (NSObject <FileItemTest>*) fileItemMask;
- (BOOL) fileItemMaskEnabled;

@end
