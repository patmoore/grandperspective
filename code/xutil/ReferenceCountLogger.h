#import <Cocoa/Cocoa.h>

@interface ReferenceCountLogger : NSObject {
  NSObject  *wrapped;
}

- (id) initWithObject:(NSObject*)wrapped;

@end
