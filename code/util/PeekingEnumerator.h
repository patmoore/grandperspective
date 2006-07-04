#import <Cocoa/Cocoa.h>


@interface PeekingEnumerator : NSObject {

  NSEnumerator*  enumerator;
  id  nextObject;
  
}

- (id) initWithEnumerator:(NSEnumerator*)enumerator;

- (id) nextObject;

- (id) peekObject;

@end
