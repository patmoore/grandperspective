#import <Cocoa/Cocoa.h>

@protocol FileItemHashingScheme;

@interface FileItemHashingCollection : NSObject {

  NSMutableDictionary  *schemesDictionary;

}

+ (FileItemHashingCollection*) defaultFileItemHashingCollection;

- (id) initWithDictionary: (NSDictionary *)dictionary;

- (void) addFileItemHashingScheme: (NSObject <FileItemHashingScheme> *)scheme 
           key: (NSString *)key;
- (void) removeFileItemHashingSchemeForKey: (NSString *)key;

- (NSArray*) allKeys;
- (NSObject <FileItemHashingScheme> *) fileItemHashingSchemeForKey: 
                                                              (NSString *)key;

@end
