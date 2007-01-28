#import <Cocoa/Cocoa.h>


@interface FileSizeMeasureCollection : NSObject {

  NSDictionary  *dictionary;

}

+ (FileSizeMeasureCollection*) defaultFileSizeMeasureCollection;

- (id) initWithDictionary: (NSDictionary *)dict;

- (NSArray*) allKeys;
- (int) fileSizeMeasureForKey: (NSString *)key;

@end
