#import "NotifyingDictionary.h"

// Just for checking which methods are safe to invoke on the dictionary (i.e.
// which won't mutate it).
static NSDictionary  *immutableDict = nil;


@implementation NotifyingDictionary

// Overrides designated initialiser
- (id) init {
  return [self initWithDictionary:
                             [NSMutableDictionary dictionaryWithCapacity:32]];
}

- (id) initWithDictionary:(NSMutableDictionary*)dictVal {
  return [self initWithDictionary:dictVal 
                  notificationCenter:[NSNotificationCenter defaultCenter]];
}

- (id) initWithNotificationCenter:(NSNotificationCenter*)notificationCenterVal {
  return [self initWithDictionary:
                               [NSMutableDictionary dictionaryWithCapacity:32]
                 notificationCenter:notificationCenterVal];
}

- (id) initWithDictionary:(NSMutableDictionary*)dictVal 
    notificationCenter:(NSNotificationCenter*)notificationCenterVal {
  if (self = [super init]) {
    dict = [dictVal retain];
    notificationCenter = [notificationCenterVal retain];
    
    if (immutableDict == nil) {
      immutableDict = [[NSDictionary alloc] init];
    }
  }
  
  return self;
}

- (void) dealloc {
  [dict release];
  [notificationCenter release];
}


- (BOOL) addObject:(id)object forKey:(id)key {
  if ([dict objectForKey:key] != nil) {
    return NO;
  }
  else {
    [dict setObject:object forKey:key];
    [notificationCenter postNotificationName:@"objectAdded"
                          object:self
                          userInfo:[NSDictionary dictionaryWithObject:key
                                                   forKey:@"key"]];
    return YES;
  }
}

- (BOOL) removeObjectForKey:(id)key {
  if ([dict objectForKey:key] == nil) {
    return NO;
  }
  else {
    [dict removeObjectForKey:key];
    [notificationCenter postNotificationName:@"objectRemoved"
                          object:self
                          userInfo:[NSDictionary dictionaryWithObject:key
                                                   forKey:@"key"]];
    return YES;
  }
}

- (BOOL) updateObject:(id)object forKey:(id)key {
  id  oldObject = [dict objectForKey:key];
  if (oldObject == nil) {
    return NO;
  }
  else {
    if (oldObject != object) {
      // Object (reference) changed.
      [dict setObject:object forKey:key];
    }
    
    // Fire notification even when reference stayed the same. Object may have
    // been internally modified.
    [notificationCenter postNotificationName:@"objectChanged"
                          object:self
                          userInfo:[NSDictionary dictionaryWithObject:key
                                                   forKey:@"key"]];
    return YES;
  }
}

- (BOOL) moveObjectFromKey:(id)oldKey toKey:(id)newKey {
  id  object = [dict objectForKey:oldKey];
  if (object == nil ||
      [dict objectForKey:newKey] != nil) {
    return NO;
  }
  else {
    [dict removeObjectForKey:oldKey];
    [dict setObject:object forKey:newKey];
    [notificationCenter postNotificationName:@"objectRenamed"
                          object:self
                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   @"oldkey", oldKey, 
                                                   @"newkey", newKey, nil]];
    return YES;
  }
}


- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel {
  NSMethodSignature  *sig = 
    [[self class] instanceMethodSignatureForSelector:sel];

  if (sig == nil) {
    sig = [immutableDict methodSignatureForSelector:sel];
  }
  NSAssert(sig != nil, @"Selector not supported by class or wrapped class."); 
  return sig;
}

- (void)forwardInvocation:(NSInvocation*)inv {
  if ([immutableDict respondsToSelector:[inv selector]]) {
    // Note: testing on "immutableDict", but invoking on "dict"
    [inv invokeWithTarget:dict];
  }
  else {
    [super forwardInvocation:inv];
  }
}


@end
