#import <Cocoa/Cocoa.h>


@protocol FileItemTest;


@interface DirectoryViewControlSettings : NSObject {
  NSString  *hashingKey;
  NSObject <FileItemTest>  *mask;
  BOOL  maskEnabled;
}

- (id) initWithHashingKey: (NSString *)key 
         mask: (NSObject <FileItemTest> *)mask
         maskEnabled: (BOOL) maskEnabled;

- (NSString*) fileItemHashingKey;

- (NSObject <FileItemTest>*) fileItemMask;
- (BOOL) fileItemMaskEnabled;

@end
