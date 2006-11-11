#import <Cocoa/Cocoa.h>

@class FileItemHashing;

@interface FileItemHashingCollection : NSObject {
  NSMutableDictionary  *hashingDictionary;
  NSString  *defaultKey;
}

+ (FileItemHashingCollection*) defaultFileItemHashingCollection;

- (id) initWithDictionary: (NSDictionary *)dictionary;
- (id) initWithDictionary: (NSDictionary *)dictionary 
         defaultKey: (NSString *)defaultKeyVal;

- (void) addFileItemHashing: (FileItemHashing *)hashing key: (NSString *)key;
- (void) removeFileItemHashingForKey: (NSString *)key;
- (void) setKeyForDefaultHashing: (NSString *)key;

- (NSArray*) allKeys;
- (NSString*) keyForDefaultHashing;
- (FileItemHashing*) fileItemHashingForKey: (NSString *)key;

@end
