#import <Cocoa/Cocoa.h>

@class NotifyingDictionary;
@protocol FileItemTest;
@protocol StringTest;

@interface FileItemTestRepository : NSObject {
  NotifyingDictionary  *testsByName;
}

+ (FileItemTestRepository*) defaultFileItemTestRepository;

- (NotifyingDictionary*) testsByNameAsNotifyingDictionary;

+ (NSObject <FileItemTest> *) fileItemTestFromDictionary: (NSDictionary *)dict;
+ (NSObject <StringTest> *) stringTestFromDictionary: (NSDictionary *)dict;

@end
