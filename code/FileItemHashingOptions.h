#import <Cocoa/Cocoa.h>

@class FileItemHashing;

@interface FileItemHashingOptions : NSObject {
  NSDictionary  *optionsDictionary;
  NSString      *defaultKey;
}

+ (FileItemHashingOptions*) defaultFileItemHashingOptions;

- (id) initWithDictionary:(NSDictionary*)dictionary;
- (id) initWithDictionary:(NSDictionary*)dictionary defaultKey:defaultKeyVal;

- (NSArray*) allKeys;
- (NSString*) keyForDefaultHashing;
- (FileItemHashing*) fileItemHashingForKey:(NSString*)key;

@end
