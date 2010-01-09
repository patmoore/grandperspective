#import "UniqueTagsTransformer.h"


@implementation UniqueTagsTransformer

+ (Class) transformedValueClass {
  return [NSNumber class];
}

+ (BOOL) allowsReverseTransformation {
  return YES; 
}


+ (UniqueTagsTransformer *) defaultUniqueTagsTransformer {
  static UniqueTagsTransformer  *defaultUniqueTagsTransformer = nil;
  
  if (defaultUniqueTagsTransformer == nil) {
    defaultUniqueTagsTransformer = [[UniqueTagsTransformer alloc] init];
  }
  
  return defaultUniqueTagsTransformer;
}


- (id) init {
  if (self = [super init]) {
    valueToTag = [[NSMutableDictionary alloc] initWithCapacity: 64];
    tagToValue = [[NSMutableDictionary alloc] initWithCapacity: 64];
    
    nextTag = 0;
  }
  
  return self;
}

- (void) dealloc {
  [valueToTag release];
  [tagToValue release];
  
  [super dealloc];
}


- (id) transformedValue:(id) value {
  if (value == nil) {
    // Gracefully handle nil values.
    return nil;
  }

  id  tag = [valueToTag objectForKey: value];
 
  if (tag == nil) {
    tag = [NSNumber numberWithInt: nextTag++];

    [valueToTag setObject: tag forKey: value];
    [tagToValue setObject: value forKey: tag];
  }
  
  return tag;
}

- (id) reverseTransformedValue: (id) tag {
  id  value = [tagToValue objectForKey: tag];
  
  NSAssert( value!=nil, @"Unknown tag value.");
  
  return value;
}


- (void) addLocalisedNames:(NSArray *)names 
           toPopUp:(NSPopUpButton *)popUp
           select:(NSString *)selectName
           table:(NSString *)tableName {
  NSEnumerator  *nameEnum = [names objectEnumerator];
  NSString  *name;
  
  while (name = [nameEnum nextObject]) {
    [self addLocalisedName: name 
            toPopUp: popUp
            select: [name isEqualToString: selectName]
            table: tableName];
  }
}

- (void) addLocalisedName:(NSString *)name 
           toPopUp:(NSPopUpButton *)popUp
           select:(BOOL) select
           table:(NSString *)tableName {
  NSBundle  *mainBundle = [NSBundle mainBundle];
  NSString  *localizedName = 
    [mainBundle localizedStringForKey: name value: nil table: tableName];

  int  tag = [[self transformedValue: name] intValue];
  [popUp addItemWithTitle: localizedName];
  [[popUp lastItem] setTag: tag];
  
  if (select) {
    [popUp selectItemAtIndex: [popUp numberOfItems] - 1];
  }
}


- (NSString *) nameForTag: (int) tag {
  return [self reverseTransformedValue: [NSNumber numberWithInt: tag]];
}

/* Returns the tag for the locale-independent name.
 */
- (int) tagForName:(NSString *)name {
  return [[self transformedValue: name] intValue];
}

@end
