#import "ItemPathBuilder.h"

#import "FileItem.h"
#import "ItemPathModel.h"
#import "TreeLayoutBuilder.h"


@interface ItemPathBuilder (PrivateMethods)

// Implicitly implement "TreeLayoutTraverser" protocol.
- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth;

@end


@implementation ItemPathBuilder

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use -initWithTree instead.");
}

- (id) initWithPathModel:(ItemPathModel*)pathModelVal {
  if (self = [super init]) {
    pathModel = [pathModelVal retain];    
  }
  
  return self;
}

- (void) dealloc {
  [pathModel release];

  [super dealloc];
}

- (void) buildVisibleItemPathToPoint:(NSPoint)point 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder 
           bounds:(NSRect)bounds {
  // Don't generate notifications while the path is being built.
  [pathModel suppressItemPathChangedNotifications:YES];
  
  [pathModel clearVisibleItemPath];
  buildTargetPoint = point;

  id  traverser = self;
  [layoutBuilder layoutItemTree:[pathModel visibleItemTree] inRect:bounds
                   traverser:traverser];
  
  [pathModel suppressItemPathChangedNotifications:NO];
}

@end


@implementation ItemPathBuilder (PrivateMethods)

- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  if (!NSPointInRect(buildTargetPoint, rect)) {
    return NO;
  }

  if (depth > 0) {
    [pathModel extendVisibleItemPath:item];
  }

  // track path further
  return YES;
}

@end // @implementation ItemPathBuilder (PrivateMethods)
