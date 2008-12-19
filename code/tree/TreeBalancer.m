#import "TreeBalancer.h"

#import "Item.h"
#import "CompoundItem.h"
#import "PeekingEnumerator.h"

int compareBySize(id item1, id item2, void* context) {
  ITEM_SIZE  size1 = [item1 itemSize];
  ITEM_SIZE  size2 = [item2 itemSize];
  
  if (size1 < size2) {
    return NSOrderedAscending;
  }
  if (size1 > size2) {
    return NSOrderedDescending;
  }
  return NSOrderedSame;
}


@implementation TreeBalancer

- (id) init {
  if (self = [super init]) {
    tmpArray = [[NSMutableArray alloc] initWithCapacity:1024];

    excludeZeroSizedItems = YES;
  }
  
  return self;
}

- (void) dealloc {
  [tmpArray release];

  [super dealloc];
}


- (void) setExcludeZeroSizedItems: (BOOL)flag {
  excludeZeroSizedItems = flag;
}

- (BOOL) excludeZeroSizedItems {
  return excludeZeroSizedItems;
}



// Note: assumes that array may be modified for sorting!
- (Item*) createTreeForItems: (NSMutableArray*)items {

  if ([items count]==0) {
    // No items, so nothing needs doing: return immediately.
    return nil;
  }
  
  [items sortUsingFunction:compareBySize context:nil];

  // Not using auto-release to minimise size of auto-release pool.
  PeekingEnumerator  *sortedItems = 
    [[PeekingEnumerator alloc] initWithEnumerator:[items objectEnumerator]];

  if (excludeZeroSizedItems) {
    while ([sortedItems peekObject] != nil &&
           [[sortedItems peekObject] itemSize] == 0) {
      [sortedItems nextObject];
    }
  }
  
  NSMutableArray*  sortedBranches = tmpArray;
  NSAssert( tmpArray!=nil && [tmpArray count]==0, 
            @"Temporary array not valid." );
  
  int  branchesGetIndex = 0;
  int  numBranches = 0;

  while (YES) {
    Item*  first = nil;
    Item*  second = nil;

    while (second == nil) {
      Item*  smallest;

      if ([sortedItems peekObject]==nil || // Out of leafs, or
          (branchesGetIndex < numBranches && // orphaned branches exist
           compareBySize([sortedBranches objectAtIndex:branchesGetIndex],
                         [sortedItems peekObject], nil) ==
           NSOrderedAscending)) {      // and the branch is smaller.
        if (branchesGetIndex < numBranches) {
          smallest = [sortedBranches objectAtIndex:branchesGetIndex++];
        }
        else {
          // We're finished building the tree
          
          // Note: with "excludeZeroSizedItems" set to YES, first can actually
          // be nil but that is okay.
          [first retain];
        
          // Clean up
          [sortedBranches removeAllObjects]; // Keep array for next time.
          [sortedItems release];
          
          return [first autorelease];
        }
      }
      else {
        smallest = [sortedItems nextObject];
      }
      NSAssert(smallest != nil, @"Smallest is nil.");
      
      if (first == nil) {
        first = smallest;
      }
      else {
        second = smallest;
      }
    }
    
    CompoundItem  *newBranch = [[CompoundItem allocWithZone: [first zone]] 
                                   initWithFirst: first second: second];
    numBranches++;
    [sortedBranches addObject:newBranch];
    // Not auto-releasing to minimise size of auto-release pool.
    [newBranch release];
  }
}

@end // @implementation TreeBalancer