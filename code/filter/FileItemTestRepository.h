#import <Cocoa/Cocoa.h>

@class NotifyingDictionary;

@interface FileItemTestRepository : NSObject {
  NotifyingDictionary  *testsByName;
}

+ (FileItemTestRepository*) defaultFileItemTestRepository;

- (NotifyingDictionary*) testsByNameAsNotifyingDictionary;

@end
