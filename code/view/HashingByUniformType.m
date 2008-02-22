#import "HashingByUniformType.h"

#import "PlainFileItem.h"
#import "UniformType.h"
#import "UniformTypeInventory.h"
#import "UniformTypeRanking.h"


@implementation HashingByUniformType

- (id) init {
  if (self = [super init]) {
    hashForUTICache = 
      [[NSMutableDictionary dictionaryWithCapacity: 16] retain];
    
    orderedTypes = [[[UniformTypeRanking defaultUniformTypeRanking]
                       uniformTypeRanking] retain];
  }
  
  return self;
}

- (void) dealloc {
  [hashForUTICache release];

  [orderedTypes release];
  
  [super dealloc];
}


- (int) hashForFileItem: (PlainFileItem *)item depth: (int)depth {
  UniformType  *type = [item uniformType];
  
  if (type == nil) {
    // Unknown type
    return INT_MAX;
  }
  
  NSNumber  *hash =  
              [hashForUTICache objectForKey: [type uniformTypeIdentifier]];
  if (hash != nil) {
    return [hash intValue];
  }
  
  NSString  *uti = [type uniformTypeIdentifier];
  
  NSSet  *ancestorTypes = [type ancestorTypes];
  int  utiIndex = 0;
  
  NSLog(@"Searching for %@", uti);
  while (utiIndex < [orderedTypes count]) {
    UniformType  *orderedType = [orderedTypes objectAtIndex: utiIndex];
  
    if (type == orderedType || [ancestorTypes containsObject: orderedType]) {
      // Found the first type in the list that the file item conforms to.
      
      NSLog(@"Match found: %@", [orderedType uniformTypeIdentifier]);
      
      // FIXME: This is not thread-safe. Each thread should probably use its
      // own cache (as is done using a context by file item tests for caching 
      // path names).
      [hashForUTICache setObject: [NSNumber numberWithInt: utiIndex]
                         forKey: [type uniformTypeIdentifier]];
      return utiIndex;
    }
    
    utiIndex++;
  }
  
  NSAssert(NO, @"No conforming type found.");
}

- (BOOL) canProvideLegend {
  return YES;
}

- (NSString *) descriptionForHash: (int)hash {
  if (hash < 0 || hash >= [orderedTypes count]) {
    return nil;
  }
  
  UniformType  *type = [orderedTypes objectAtIndex: hash];
   
  return [type description];
}

@end
