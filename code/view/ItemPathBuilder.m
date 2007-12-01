#import "ItemPathBuilder.h"

#import "FileItem.h"
#import "ItemPathModel.h"
#import "TreeLayoutBuilder.h"


@implementation ItemPathBuilder

- (FileItem *) selectItemAtPoint: (NSPoint)point 
                 startingAtTree: (FileItem *)treeRoot
                 usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder 
                 bounds: (NSRect)bounds
                 updatePath: (ItemPathModel *)pathModelVal {
  NSAssert(pathModel==nil, @"Path model should be nil.");
  pathModel = pathModelVal;
  visibleTree = [pathModel visibleTree];
  insideVisibleTree = NO;
           
  // Don't generate notifications while the path is being built.
  [pathModel suppressSelectedItemChangedNotifications: YES];
  
  [pathModel clearVisiblePath];
  
  FileItem  *retVal = [self selectItemAtPoint: point 
                              startingAtTree: treeRoot 
                              usingLayoutBuilder: layoutBuilder 
                              bounds: bounds];
  
  [pathModel suppressSelectedItemChangedNotifications: NO];
  visibleTree = nil;
  pathModel = nil;
  
  return retVal;
}

- (FileItem *) selectItemAtPoint: (NSPoint)point 
                 startingAtTree: (FileItem *)treeRoot
                 usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder 
                 bounds: (NSRect)bounds {
  NSAssert(foundItem==nil, @"foundItem should be nil.");
  
  targetPoint = point;

  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];
  
  FileItem  *retVal = foundItem;
  foundItem = nil;
  return retVal;
}


- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  if (!NSPointInRect(targetPoint, rect)) {
    return NO;
  }
  
  if (pathModel != nil) {
    if (item == visibleTree) {
      insideVisibleTree = YES;
    }
    else if (insideVisibleTree) {
      // Note: Append the visible item which is not the visible tree root 
      // itself) to the path.
      [pathModel extendVisiblePath: item];
    }
  }

  if (! [item isVirtual]) {
    foundItem = (FileItem *)item;
  }
  
  // track path further
  return YES;
}

- (void) emergedFromItem:(Item*)item {
  if (item == visibleTree) {
    insideVisibleTree = NO;
  }
}

@end // @implementation ItemPathBuilder
