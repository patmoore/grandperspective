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


- (id) transformedValue: (id) value {
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



- (void) addLocalisedNamesToPopUp: (NSPopUpButton *)popUp
           names: (NSArray *)names
           select: (NSString *)selectName
           table: (NSString *)tableName {
  NSBundle  *mainBundle = [NSBundle mainBundle];

  NSEnumerator  *enumerator = [names objectEnumerator];
  NSString  *name;
  NSString  *localizedSelect = nil;
  
  while (name = [enumerator nextObject]) {
    NSString  *localizedName = 
      [mainBundle localizedStringForKey: name value: nil table: tableName];

    if ([name isEqualToString: selectName]) {
      localizedSelect = localizedName;
    }
    
    int  tag = [[self transformedValue: name] intValue];
    
    [popUp addItemWithTitle: localizedName];
    [[popUp lastItem] setTag: tag];
  }
  
  if (localizedSelect != nil) {
    [popUp selectItemWithTitle: localizedSelect];
  }
}

- (NSString *) nameForTag: (int) tag {
  return [self reverseTransformedValue: [NSNumber numberWithInt: tag]];
}

@end
