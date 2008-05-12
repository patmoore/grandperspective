#import "ItemPathBuilder.h"

#import "DirectoryItem.h"
#import "ItemPathModel.h"
#import "TreeLayoutBuilder.h"


@implementation ItemPathBuilder

- (FileItem *) itemAtPoint: (NSPoint) point 
                 startingAtTree: (FileItem *)treeRoot
                 usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder 
                 bounds: (NSRect) bounds
                 updatePath: (ItemPathModel *)pathModelVal {
  NSAssert(pathModel==nil, @"Path model should be nil.");
  pathModel = pathModelVal;
  visibleTree = [pathModel visibleTree];
  
  [pathModel clearVisiblePath];

  insideVisibleTree = NO;  
  FileItem  *retVal = [self itemAtPoint: point 
                              startingAtTree: treeRoot 
                              usingLayoutBuilder: layoutBuilder 
                              bounds: bounds];
  
  visibleTree = nil;
  pathModel = nil;
  
  return retVal;
}

- (FileItem *) itemAtPoint: (NSPoint)point 
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
  
  return YES;
}

- (void) emergedFromItem:(Item*)item {
  if (item == visibleTree) {
    insideVisibleTree = NO;
  }
}

@end // @implementation ItemPathBuilder
