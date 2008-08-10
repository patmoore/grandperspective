#import <Cocoa/Cocoa.h>


@interface ReadTaskInput : NSObject {
  NSString  *path;
}

- (id) initWithPath: (NSString *)path;

- (NSString *) path;

@end
