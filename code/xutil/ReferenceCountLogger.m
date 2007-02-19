#import "ReferenceCountLogger.h"


@implementation ReferenceCountLogger

- (id) init {
  NSAssert(NO, @"Use initWithObject: instead.");
}

- (id) initWithObject:(NSObject*)wrappedVal {
  if (self = [super init]) {
    wrapped = [wrappedVal retain];
    NSLog(@"Retain count: %d", [wrapped retainCount]); 
  }
  return self;
}

- (void) dealloc {
  NSLog(@"Dealloc");
  [wrapped release];
  
  [super dealloc];
}

- (id)retain {
  NSLog(@"Retaining");
  return [super retain];
}

- (oneway void)release {
  NSLog(@"Releasing");
  [super release];
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel {
  NSMethodSignature  *sig = 
    [[self class] instanceMethodSignatureForSelector:sel];

  if (sig == nil) {
    sig = [wrapped methodSignatureForSelector:sel];
  }
  NSAssert(sig != nil, @"Selector not supported by class or wrapped class."); 
  return sig;
}

- (void)forwardInvocation:(NSInvocation*)inv {
  if ([wrapped respondsToSelector:[inv selector]]) {
    [inv invokeWithTarget:wrapped];
  }
  else {
    [super forwardInvocation:inv];
  }
}
 
@end
