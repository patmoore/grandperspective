#import "AsynchronousItemTreeDrawer.h"

#import "ItemTreeDrawer.h"
#import "Item.h"
#import "FileItemHashing.h"
#import "TreeLayoutBuilder.h"

enum {
  // Indicates that there is a drawing task in progress or ready to be
  // executed (or that the drawer has been disposed and that the thread
  // needs to terminate).
  DRAWING_THREAD_BUSY = 345,

  // Indicates that the thread can block or is blocking, waiting for a new
  // drawing task (or for the drawer to be disposed).
  DRAWING_THREAD_IDLE
};

@interface AsynchronousItemTreeDrawer (PrivateMethods)

- (void) defaultPostNotificationName:(NSString*)notificationName;
- (void) imageDrawLoop;

@end

@implementation AsynchronousItemTreeDrawer

// Overrides designated initialiser of superclass.
- (id) init {
  return [self initWithItemTreeDrawer: 
                 [[[ItemTreeDrawer alloc] init] autorelease]];
}

- (id) initWithItemTreeDrawer: (ItemTreeDrawer*)drawerVal {
  if (self = [super init]) {
    drawer = [drawerVal retain];
    fileItemHashing = [[drawer fileItemHashing] retain];
  
    workLock = [[NSConditionLock alloc] initWithCondition:DRAWING_THREAD_IDLE];
    settingsLock = [[NSLock alloc] init];
    alive = YES;

    [NSThread detachNewThreadSelector:@selector(imageDrawLoop)
                toTarget:self withObject:nil];
  }
  return self;
}


- (void) dealloc {
  NSLog(@"AsynchronousItemTreeDrawer-dealloc");

  NSAssert(!alive, @"Deallocating without a dispose.");

  [drawer release];
  [fileItemHashing release];
  
  [image release];
  
  [workLock release];
  [settingsLock release];
  
  [drawItemTree release];
  
  [super dealloc];
}


- (void) dispose {
  [settingsLock lock];
  NSAssert(alive, @"Disposing of an already dead drawer.");

  alive = NO;

  if ([workLock condition] == DRAWING_THREAD_BUSY) {
    // Abort drawing 
    [drawer abortDrawing];
  }
  else {
    // Notify waiting thread
    [workLock lock];
    [workLock unlockWithCondition:DRAWING_THREAD_BUSY];
  }
  
  [settingsLock unlock];
}


- (void) setFileItemHashing:(FileItemHashing*)fileItemHashingVal {
  [settingsLock lock];

  [fileItemHashingVal retain];
  [fileItemHashing release];
  fileItemHashing = fileItemHashingVal;

  // Invalidate the image.
  [image release];
  image = nil;

  [settingsLock unlock];
}

- (FileItemHashing*) fileItemHashing {
  return fileItemHashing;
}


- (TreeLayoutBuilder*) treeLayoutBuilder {
  return [drawer treeLayoutBuilder];
}


- (NSImage*) getImage {
  [settingsLock lock];
  NSImage*  returnImage = [[image retain] autorelease];
  [settingsLock unlock];
  
  return returnImage;
}

- (void) resetImage {
  [settingsLock lock];
  [image release];
  image = nil;
  [settingsLock unlock];
}


- (void) asynchronouslyDrawImageOfItemTree: (Item*)itemTreeRoot
           inRect: (NSRect)bounds {
  [settingsLock lock];
  NSAssert(alive, @"Disturbing a dead drawer.");
  
  if (drawItemTree != itemTreeRoot) {
    [drawItemTree release];
    drawItemTree = [itemTreeRoot retain];
  }
  drawInRect = bounds;

  if ([workLock condition] == DRAWING_THREAD_BUSY) {
    // Abort drawing 
    [drawer abortDrawing];
  }
  else {
    // Notify waiting thread
    [workLock lock];
    [workLock unlockWithCondition:DRAWING_THREAD_BUSY];
  }

  [settingsLock unlock];
}

@end

@implementation AsynchronousItemTreeDrawer (PrivateMethods)

- (void) defaultPostNotificationName:(NSString*)notificationName {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:notificationName object:self];
}

- (void) imageDrawLoop {
  BOOL  terminate = NO;
  
  while (!terminate) {
    NSAutoreleasePool  *pool = [[NSAutoreleasePool alloc] init];

    [workLock lockWhenCondition:DRAWING_THREAD_BUSY];
            
    [settingsLock lock];
    if (alive) {
      NSAssert(drawItemTree != nil, @"Draw task not set properly.");
      Item  *tree = [drawItemTree autorelease];
      NSRect  rect = drawInRect;
      [drawer setFileItemHashing:fileItemHashing];

      drawItemTree = nil;

      // Drawing may have been aborted. Clear the flag so that the drawing 
      // task at least starts (it may be aborted again of course).
      //
      // Note: This should happen in a "settingsLock" block, and can therefore
      // not be done by the drawer in its drawImageOfItemTree:inRect: method.
      [drawer resetAbortDrawingFlag];

      [settingsLock unlock]; // Don't lock settings while drawing.
      image = [drawer drawImageOfItemTree: tree inRect: rect];
      [settingsLock lock];
      
      if (image != nil) {
        [self performSelectorOnMainThread:@selector(defaultPostNotificationName:)
                withObject:@"itemTreeImageReady" waitUntilDone:NO];
      }
      
      if (alive && drawItemTree==nil) {      
        [workLock unlockWithCondition:DRAWING_THREAD_IDLE];
      }
      else {
        [workLock unlockWithCondition:DRAWING_THREAD_BUSY];
      }
    }
    else {
      terminate = YES;
    }
    [settingsLock unlock];
    
    [pool release];
  }
  NSLog(@"Thread terminated.");
}

@end // AsynchronousItemTreeDrawer (PrivateMethods)