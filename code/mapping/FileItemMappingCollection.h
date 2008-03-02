#import <Cocoa/Cocoa.h>

@protocol FileItemMappingScheme;

/* A collection of file item mapping schemes.
 */
@interface FileItemMappingCollection : NSObject {

  NSMutableDictionary  *schemesDictionary;

}

+ (FileItemMappingCollection*) defaultFileItemMappingCollection;

- (id) initWithDictionary: (NSDictionary *)dictionary;

- (void) addFileItemMappingScheme: (NSObject <FileItemMappingScheme> *)scheme 
           key: (NSString *)key;
- (void) removeFileItemMappingSchemeForKey: (NSString *)key;

- (NSArray*) allKeys;
- (NSObject <FileItemMappingScheme> *) fileItemMappingSchemeForKey: 
                                                              (NSString *)key;

@end
