#import "HashingByUniformType.h"

#import "UniformType.h"
#import "UniformTypeInventory.h"


NSString  *UniformTypesOrderingKey = @"uniformTypesOrdering";


@implementation HashingByUniformType

- (id) init {
  if (self = [super init]) {
    hashForUTICache = 
      [[NSMutableDictionary dictionaryWithCapacity: 16] retain];
    
    typeInventory = [[UniformTypeInventory defaultUniformTypeInventory] retain];
    
    NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
    orderedUTIs = [[userDefaults arrayForKey: UniformTypesOrderingKey] retain];
    if (orderedUTIs == nil) {
      orderedUTIs = [[NSArray array] retain];
    }
    
    unorderedUTIs = [[NSMutableSet setWithCapacity: [orderedUTIs count] + 16]
                         retain];
    [unorderedUTIs addObjectsFromArray: orderedUTIs];
    
    [userDefaults addObserver: self forKeyPath: UniformTypesOrderingKey
                    options: nil context: nil];
                    
    pendingOwnChanges = 0;
  }
  
  return self;
}

- (void) dealloc {
  [hashForUTICache release];
  [typeInventory release];

  [orderedUTIs release];
  [unorderedUTIs release];
  
  [super dealloc];
}


- (int) hashForFileItem: (FileItem *)item depth: (int)depth {
  UniformType  *type = [typeInventory uniformTypeForFileItem: item];
  
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
  if (! [unorderedUTIs containsObject: uti]) {
    // This type has not yet been encountered. Add it to (the back of) the
    // list of ordered UTIs.
    
    NSArray  *newArray = [orderedUTIs arrayByAddingObject: uti];
    [orderedUTIs release];
    orderedUTIs = [newArray retain];
    
    [unorderedUTIs addObject: uti];
    
    pendingOwnChanges++;    
    NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject: orderedUTIs forKey: UniformTypesOrderingKey];

    // TODO: Once the order of the UTIs can be manipulated by user, all
    // (possibly virtual) ancestor types should automatically appear in this
    // list as well. Currently, only the actual types of encountered files
    // are added.
  }

  
  NSSet  *ancestorTypes = [type ancestorTypes];
  int  utiIndex = 0;
  
  NSLog(@"Searching for %@", uti);
  while (utiIndex < [orderedUTIs count]) {
    UniformType  *orderedType = 
      [typeInventory uniformTypeForIdentifier: 
                       [orderedUTIs objectAtIndex: utiIndex]];
  
    if (type == orderedType || [ancestorTypes containsObject: orderedType]) {
      // Found the first type in the list that the file item conforms to.
      
      NSLog(@"Match found: %@", [orderedType uniformTypeIdentifier]);
      
      [hashForUTICache setObject: [NSNumber numberWithInt: utiIndex]
                         forKey: [type uniformTypeIdentifier]];
      return utiIndex;
    }
    
    utiIndex++;
  }
  
  NSAssert(NO, @"No conforming type found.");
}


- (void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id) object 
           change: (NSDictionary *)change context: (void *)context {
  if (object == [NSUserDefaults standardUserDefaults]) {
    if ([keyPath isEqualToString: UniformTypesOrderingKey]) {
      NSLog(@"UniformTypesOrderingKey value changed.");

      if (pendingOwnChanges > 0) {
        pendingOwnChanges--;
        NSLog(@"Change possibly mine. Still pending: %d", pendingOwnChanges);
      }
      else {
        NSLog(@"External change. Clearing cache");
        [hashForUTICache removeAllObjects];
      }
    }
  }
}

@end
