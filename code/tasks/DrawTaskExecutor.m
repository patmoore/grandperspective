#import "DrawTaskExecutor.h"

#import "FileItem.h"
#import "ItemTreeDrawer.h"
#import "DrawTaskInput.h"
#import "FileItemHashing.h"

@implementation DrawTaskExecutor

// Overrides designated initialiser
- (id) init {
  return [self initWithTreeDrawer:[[[ItemTreeDrawer alloc] init] autorelease]];
}

- (id) initWithTreeDrawer:(ItemTreeDrawer*)treeDrawerVal {
  if (self = [super init]) {
    treeDrawer = [treeDrawerVal retain];
    fileItemHashing = [[treeDrawer fileItemHashing] retain];
    fileItemMask = [[treeDrawer fileItemMask] retain];

    enabled = YES;
  }
  return self;
}

- (void) dealloc {
  [treeDrawer release];
  
  [fileItemHashing release];
  [fileItemMask release];
  
  [super dealloc];
}


- (void) setFileItemHashing:(FileItemHashing*)fileItemHashingVal {
  if (fileItemHashingVal != fileItemHashing) {
    [fileItemHashing release];
    fileItemHashing = [fileItemHashingVal retain];
  }
}

- (FileItemHashing*) fileItemHashing {
  return fileItemHashing;
}


- (void) setFileItemMask:(NSObject <FileItemTest>*)fileItemMaskVal {
  if (fileItemMaskVal != fileItemMask) {
    [fileItemMask release];
    fileItemMask = [fileItemMaskVal retain];
  }
}

- (NSObject <FileItemTest> *) fileItemMask {
  return fileItemMask;
}


- (id) runTaskWithInput: (id)input {
  if (enabled) {
    // Always set, as it may have changed.
    [treeDrawer setFileItemHashing: fileItemHashing];
    [treeDrawer setFileItemMask: fileItemMask];

    DrawTaskInput  *drawingInput = input;
    
    return [treeDrawer drawImageOfItemTree: [drawingInput itemSubTree] 
                         inRect: [drawingInput bounds]];
  }
  else {
    return nil;
  }
}


- (void) disable {
  if (enabled) {
    enabled = NO;
    [treeDrawer abortDrawing];
  }
}

- (void) enable {
  enabled = YES;
}


@end
