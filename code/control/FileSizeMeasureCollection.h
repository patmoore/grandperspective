#import <Cocoa/Cocoa.h>


@interface FileSizeMeasureCollection : NSObject {

  NSArray  *keys;

}

+ (FileSizeMeasureCollection*) defaultFileSizeMeasureCollection;

- (id) initWithKeys: (NSArray *)keys;

- (NSArray *) allKeys;

@end
