#import "NamedFilter.h"

#import "Filter.h"


@implementation NamedFilter

+ (NamedFilter *)emptyFilterWithName:(NSString *)name {
  return [[[NamedFilter alloc] initWithFilter: [Filter filter] name: name] 
              autorelease];
}

+ (NamedFilter *)namedFilter:(Filter *)filter name:(NSString *)name {
  return [[[NamedFilter alloc] initWithFilter: filter name: name] autorelease];
}


// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithFilter:name: instead.");
}

- (id) initWithFilter:(Filter *)filterVal name:(NSString *)nameVal {
  if (self = [super init]) {
    filter = [filterVal retain];
    name = [nameVal retain];
  }
  return self;
}

- (void) dealloc {
  [filter release];
  [name release];
  
  [super dealloc];
}

- (Filter *)filter {
  return filter;
}

- (NSString *)name {
  return name;
}

- (NSString *)localizedName {
  return [[NSBundle mainBundle] localizedStringForKey: name 
                                  value: nil table: @"Names"];
}

@end
