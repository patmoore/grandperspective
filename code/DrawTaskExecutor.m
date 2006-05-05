#import "DrawTaskExecutor.h"

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

    enabled = YES;
  }
  return self;
}

- (void) dealloc {
  [treeDrawer release];
  [fileItemHashing release];
  
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


- (id) runTaskWithInput: (id)input {
  if (enabled) {
    // Always set, as it may have changed.
    [treeDrawer setFileItemHashing:fileItemHashing];

    DrawTaskInput  *drawingInput = input;
    
    return [treeDrawer drawImageOfItemTree: [drawingInput itemTree] 
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
