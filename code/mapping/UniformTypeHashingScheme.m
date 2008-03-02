#import "UniformTypeHashingScheme.h"

#import "StatefulFileItemHashing.h"
#import "PlainFileItem.h"
#import "UniformType.h"
#import "UniformTypeRanking.h"


@interface HashingByUniformType : StatefulFileItemHashing {

  // Cache mapping UTIs (NSString) to integer values (NSNumber)
  NSMutableDictionary  *hashForUTICache;
  
  NSArray  *orderedTypes;
}

@end


@implementation UniformTypeHashingScheme

- (NSObject <FileItemHashing> *) fileItemHashing {
  return [[[HashingByUniformType alloc] initWithFileItemHashingScheme: self]
              autorelease];
}

@end


@implementation HashingByUniformType

- (id) initWithFileItemHashingScheme: 
                                (NSObject <FileItemHashingScheme> *)schemeVal {

  if (self = [super initWithFileItemHashingScheme: schemeVal]) {
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
  
  NSString  *uti = [type uniformTypeIdentifier];
  NSNumber  *hash = [hashForUTICache objectForKey: uti];
  if (hash != nil) {
    return [hash intValue];
  }
    
  NSSet  *ancestorTypes = [type ancestorTypes];
  int  utiIndex = 0;
  
  while (utiIndex < [orderedTypes count]) {
    UniformType  *orderedType = [orderedTypes objectAtIndex: utiIndex];
  
    if (type == orderedType || [ancestorTypes containsObject: orderedType]) {
      // Found the first type in the list that the file item conforms to.
      
      // Add it to the cache for next time.
      [hashForUTICache setObject: [NSNumber numberWithInt: utiIndex]
                         forKey: uti];
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
