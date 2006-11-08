#import <Cocoa/Cocoa.h>


@interface ColorListCollection : NSObject {

  NSMutableDictionary  *colorListDictionary;
  NSString  *keyForDefaultColorList;
}

+ (ColorListCollection*) defaultColorListCollection;

- (void) addColorList: (NSColorList *)colorList key: (NSString *)key;
- (void) removeColorListForKey: (NSString *)key;
- (void) setKeyForDefaultColorList: (NSString *)key;

- (NSArray*) allKeys;
- (NSString*) keyForDefaultColorList;
- (NSColorList*) colorListForKey: (NSString *)key;

@end
