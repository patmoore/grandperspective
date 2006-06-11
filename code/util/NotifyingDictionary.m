#import "NotifyingDictionary.h"

// Just for checking which methods are safe to invoke on the dictionary (i.e.
// which won't mutate it).
static NSDictionary  *immutableDict = nil;


@implementation NotifyingDictionary

// Overrides designated initialiser
- (id) init {
  return [self initWithCapacity:32];
}

- (id) initWithCapacity:(unsigned)capacity {
  return [self initWithCapacity:capacity initialContents:nil];
}

- (id) initWithCapacity:(unsigned)capacity
         initialContents:(NSDictionary*)contents {
  if (self = [super init]) {
    if (immutableDict == nil) {
      // Static initialisation
      immutableDict = [[NSDictionary alloc] init];
    }

    dict = [[NSMutableDictionary alloc] initWithCapacity:capacity];
    
    if (contents != nil) {
      [dict addEntriesFromDictionary:contents];
    }
    
    notificationCenter = [[NSNotificationCenter defaultCenter] retain];    
  }
  
  return self;
}

- (void) dealloc {
  [dict release];
  [notificationCenter release];
}


- (NSNotificationCenter*) notificationCenter {
  return notificationCenter;
}
  
- (void) setNotificationCenter:(NSNotificationCenter*)notificationCenterVal {
  if (notificationCenterVal != notificationCenter) {
    [notificationCenter release];
    notificationCenter = [notificationCenterVal retain];
  }
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
    [notificationCenter postNotificationName:@"objectUpdated"
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
                                                   oldKey, @"oldkey", 
                                                   newKey, @"newkey", nil]];
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
