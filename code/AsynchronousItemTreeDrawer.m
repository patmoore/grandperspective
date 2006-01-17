#import "AsynchronousItemTreeDrawer.h"

#import "ItemTreeDrawer.h"
#import "Item.h"
#import "FileItemHashing.h"
#import "TreeLayoutBuilder.h"

enum {
  IMAGE_TASK_PENDING = 345,
  NO_IMAGE_TASK
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
  
    workLock = [[NSConditionLock alloc] initWithCondition:NO_IMAGE_TASK];
    settingsLock = [[NSLock alloc] init];

    [NSThread detachNewThreadSelector:@selector(imageDrawLoop)
                toTarget:self withObject:nil];
  }
  return self;
}


- (void) dealloc {
  [drawer release];
  [fileItemHashing release];
  
  [image release];
  
  [workLock release];
  [settingsLock release];
  
  [drawItemTree release];
  
  [super dealloc];
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
  if (drawItemTree != itemTreeRoot) {
    [drawItemTree release];
    drawItemTree = [itemTreeRoot retain];
  }
  drawInRect = bounds;

  // Abort drawing (whether or not drawing is taking place).
  [drawer abortDrawing];

  if ([workLock condition] == NO_IMAGE_TASK) {
    // Notify waiting thread
    [workLock lock];
    [workLock unlockWithCondition:IMAGE_TASK_PENDING];
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
  while (YES) {
    NSAutoreleasePool  *pool = [[NSAutoreleasePool alloc] init];

    [workLock lockWhenCondition:IMAGE_TASK_PENDING];
            
    [settingsLock lock];
    NSAssert(drawItemTree != nil, @"Draw task not set properly.");
    Item  *tree = [drawItemTree autorelease];
    NSRect  rect = drawInRect;
    [drawer setFileItemHashing:fileItemHashing];

    drawItemTree = nil;

    [settingsLock unlock];
    
    image = [drawer drawImageOfItemTree: tree inRect: rect];
    
    [settingsLock lock];
    if (image != nil) {
      [self performSelectorOnMainThread:@selector(defaultPostNotificationName:)
              withObject:@"itemTreeImageReady" waitUntilDone:NO];
      
      [workLock unlockWithCondition:NO_IMAGE_TASK];
    }
    else {
      [workLock unlockWithCondition:IMAGE_TASK_PENDING];
    }
    [settingsLock unlock];
    
    [pool release];
  }
}

@end // AsynchronousItemTreeDrawer (PrivateMethods)