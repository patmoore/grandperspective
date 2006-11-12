#import <Cocoa/Cocoa.h>

@class FileItemHashing;

@interface FileItemHashingCollection : NSObject {

  NSMutableDictionary  *hashingDictionary;

}

+ (FileItemHashingCollection*) defaultFileItemHashingCollection;

- (id) initWithDictionary: (NSDictionary *)dictionary;

- (void) addFileItemHashing: (FileItemHashing *)hashing key: (NSString *)key;
- (void) removeFileItemHashingForKey: (NSString *)key;

- (NSArray*) allKeys;
- (FileItemHashing*) fileItemHashingForKey: (NSString *)key;

@end
