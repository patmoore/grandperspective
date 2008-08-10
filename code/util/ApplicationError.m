#import "ApplicationError.h"


@implementation ApplicationError

// Overrides designated initialiser
- (id) initWithDomain:(NSString *)domain code: (int)code 
         userInfo: (NSDictionary *)userInfo {
  NSAssert(NO, @"Use initWithCode:userInfo instead.");
}

- (id) initWithLocalizedDescription: (NSString *)descr {
  return [self initWithCode: -1 localizedDescription: descr];
}

- (id) initWithCode: (int)code localizedDescription: (NSString *)descr {
  return [self initWithCode: code userInfo:
            [NSDictionary dictionaryWithObject: descr
                            forKey: NSLocalizedDescriptionKey]];
}

- (id) initWithCode: (int)code userInfo: (NSDictionary *)userInfo {
  return [super initWithDomain: @"Application" code: code userInfo: userInfo];
}

+ (id) errorWithLocalizedDescription: (NSString *)descr {
  return [[[ApplicationError alloc] initWithLocalizedDescription: descr]
              autorelease];
}

+ (id) errorWithCode: (int)code localizedDescription: (NSString *)descr {
  return [[[ApplicationError alloc] initWithCode: code 
                                      localizedDescription: descr]
              autorelease];
}

+ (id) errorWithCode: (int)code userInfo: (NSDictionary *)userInfo {
  return [[[ApplicationError alloc] initWithCode: code userInfo: userInfo]
              autorelease];
}

@end
