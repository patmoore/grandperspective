#import "CompoundItem.h"


@implementation CompoundItem

+ (Item*) compoundItemWithFirst:(Item*)firstVal second:(Item*)secondVal {
  if (firstVal!=nil && secondVal!=nil) {
    return [[[CompoundItem allocWithZone: [firstVal zone]] 
                initWithFirst: firstVal second: secondVal] autorelease];
  }
  if (firstVal!=nil) {
    return firstVal;
  }
  if (secondVal!=nil) {
    return secondVal;
  }
  return nil;
}


// Overrides super's designated initialiser.
- (id) initWithItemSize:(ITEM_SIZE)size {
  NSAssert(NO, @"Use initWithFirst:second instead.");
}

- (id) initWithFirst:(Item*)firstVal second:(Item*)secondVal {
  NSAssert(firstVal!=nil && secondVal!=nil, @"Both values must be non nil.");
  
  if (self = [super initWithItemSize:([firstVal itemSize] + 
                                      [secondVal itemSize])]) {
    first = [firstVal retain];
    second = [secondVal retain];
    numFiles = [first numFiles] + [second numFiles];
  }

  return self;
}


- (void) dealloc {
  [first release];
  [second release];
  
  [super dealloc];
}


- (NSString*) description {
  return [NSString stringWithFormat:@"CompoundItem(%@, %@)", first, second];
}


- (FILE_COUNT) numFiles {
  return numFiles;
}

- (BOOL) isVirtual {
  return YES;
}


- (Item*) getFirst {
  return first;
}

- (Item*) getSecond {
  return second;
}


- (void) replaceFirst: (Item *)newItem {
  NSAssert([newItem itemSize] == [first itemSize], @"Sizes must be equal.");
  
  if (first != newItem) {
    [first release];
    first = [newItem retain];
  }
}

- (void) replaceSecond: (Item *)newItem {
  NSAssert([newItem itemSize] == [second itemSize], @"Sizes must be equal.");
  
  if (second != newItem) {
    [second release];
    second = [newItem retain];
  }
}

@end
