#import "DirectoryView.h"

#import "math.h"

#import "DirectoryItem.h"

#import "TreeLayoutBuilder.h"
#import "ItemTreeDrawer.h"
#import "ItemTreeDrawerSettings.h"
#import "ItemPathDrawer.h"
#import "ItemPathModel.h"
#import "ItemPathModelView.h"

#import "TreeLayoutTraverser.h"

#import "AsynchronousTaskManager.h"
#import "DrawTaskExecutor.h"
#import "DrawTaskInput.h"

#import "FileItemMapping.h"
#import "FileItemMappingScheme.h"


#define SCROLL_WHEEL_SENSITIVITY  6.0


NSString  *ColorPaletteChangedEvent = @"colorPaletteChanged";
NSString  *ColorMappingChangedEvent = @"colorMappingChanged";


@interface DirectoryView (PrivateMethods)

- (void) forceRedraw;

- (void) itemTreeImageReady: (id) image;

- (void) postColorPaletteChanged;
- (void) postColorMappingChanged;

- (void) selectedItemChanged: (NSNotification *)notification;
- (void) visibleTreeChanged: (NSNotification *)notification;
- (void) visiblePathLockingChanged: (NSNotification *)notification;
- (void) windowMainStatusChanged: (NSNotification *) notification;

- (void) observeColorMapping;
- (void) colorMappingChanged: (NSNotification *) notification;

- (void) updateSelectedItem: (NSPoint) point;

@end  


@implementation DirectoryView

- (id) initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    layoutBuilder = [[TreeLayoutBuilder alloc] init];
    pathDrawer = [[ItemPathDrawer alloc] init];
    
    scrollWheelDelta = 0;
  }

  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  [drawTaskManager dispose];
  [drawTaskManager release];

  [layoutBuilder release];
  [pathDrawer release];
  
  [observedColorMapping release];
  
  [pathModelView release];
  
  [treeImage release];
  
  [super dealloc];
}


- (void) postInitWithPathModelView: (ItemPathModelView *)pathModelViewVal {
  NSAssert(pathModelView==nil, @"The path model view should only be set once.");

  pathModelView = [pathModelViewVal retain];
  
  DrawTaskExecutor  *drawTaskExecutor = 
    [[DrawTaskExecutor alloc] initWithTreeContext: 
       [[pathModelView pathModel] treeContext]];
  drawTaskManager = 
    [[AsynchronousTaskManager alloc] initWithTaskExecutor: drawTaskExecutor];
  [drawTaskExecutor release];
  [self observeColorMapping];
  
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  [nc addObserver: self selector: @selector(selectedItemChanged:)
        name: SelectedItemChangedEvent object: pathModelView];
  [nc addObserver: self selector: @selector(visibleTreeChanged:)
        name: VisibleTreeChangedEvent object: pathModelView];
  [nc addObserver: self selector: @selector(visiblePathLockingChanged:)
        name: VisiblePathLockingChangedEvent 
        object: [pathModelView pathModel]];
          
  [nc addObserver: self selector: @selector(windowMainStatusChanged:)
        name: NSWindowDidBecomeMainNotification object: [self window]];
  [nc addObserver: self selector: @selector(windowMainStatusChanged:)
        name: NSWindowDidResignMainNotification object: [self window]];
  
  [self visiblePathLockingChanged: nil];
  [self setNeedsDisplay: YES];
}


- (ItemPathModelView *)pathModelView {
  return pathModelView;
}

- (FileItem *)treeInView {
  return (showEntireVolume 
          ? [pathModelView volumeTree]
          : [pathModelView visibleTree]);
}


- (ItemTreeDrawerSettings *) treeDrawerSettings {
  DrawTaskExecutor  *drawTaskExecutor = 
    (DrawTaskExecutor*)[drawTaskManager taskExecutor];

  return [drawTaskExecutor treeDrawerSettings];
}

- (void) setTreeDrawerSettings: (ItemTreeDrawerSettings *)settings {
  DrawTaskExecutor  *drawTaskExecutor = 
    (DrawTaskExecutor*)[drawTaskManager taskExecutor];

  ItemTreeDrawerSettings  *oldSettings = [drawTaskExecutor treeDrawerSettings];
  if (settings != oldSettings) {
    [oldSettings retain];

    [drawTaskExecutor setTreeDrawerSettings: settings];
    
    if ([settings colorPalette] != [oldSettings colorPalette]) {
      [self postColorPaletteChanged]; 
    }
    
    if ([settings colorMapper] != [oldSettings colorMapper]) {
      [self postColorMappingChanged]; 

      // Observe the color mapping (for possible changes to its hashing
      // implementation)
      [self observeColorMapping];
    }
    
    if ([settings showPackageContents] != [oldSettings showPackageContents]) {
      [pathModelView setShowPackageContents: [settings showPackageContents]];
    }
    
    [oldSettings release];

    [self forceRedraw];
  }
}


- (BOOL) showEntireVolume {
  return showEntireVolume;
}

- (void) setShowEntireVolume: (BOOL) flag {
  if (flag != showEntireVolume) {
    showEntireVolume = flag;
    [self forceRedraw];
  }
}


- (TreeLayoutBuilder*) layoutBuilder {
  return layoutBuilder;
}


- (void) drawRect:(NSRect)rect {
  if (pathModelView==nil) {
    return;
  }
  
  if (treeImage!=nil && !NSEqualSizes([treeImage size], [self bounds].size)) {
    treeImage = nil;
  }

  if (treeImage==nil) {
    NSAssert([self bounds].origin.x == 0 &&
             [self bounds].origin.y == 0, @"Bounds not at (0, 0)");

    // Create image in background thread.
    DrawTaskInput  *drawInput = 
      [[DrawTaskInput alloc] initWithVisibleTree: [pathModelView visibleTree] 
                               treeInView: [self treeInView]
                               layoutBuilder: layoutBuilder
                               bounds: [self bounds]];
    [drawTaskManager asynchronouslyRunTaskWithInput: drawInput callback: self 
                       selector: @selector(itemTreeImageReady:)];
    [drawInput release];
  }
  else {
    [treeImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];

    if ([pathModelView isSelectedFileItemVisible]) {
      [pathDrawer drawVisiblePath: pathModelView
                    startingAtTree: [self treeInView]
                    usingLayoutBuilder: layoutBuilder
                    bounds: [self bounds]];
    }
  }
}


- (BOOL) isOpaque {
  return YES;
}

- (BOOL) acceptsFirstResponder {
  return YES;
}

- (BOOL) becomeFirstResponder {
  return YES;
}

- (BOOL) resignFirstResponder {
  return YES;
}


- (void) keyDown: (NSEvent *)theEvent {
  NSString*  chars = [theEvent characters];
  if ([chars isEqualToString: @"]"]) {
    if (! [pathModelView selectionSticksToEndPoint]) {
      if ([pathModelView canMoveSelectionDown]) {
        [pathModelView moveSelectionDown];
      }
      else {
        [pathModelView setSelectionSticksToEndPoint: YES];
      }
    }
  }
  else if ([chars isEqualToString: @"["]) {
    if ([pathModelView canMoveSelectionUp]) {
      [pathModelView moveSelectionUp];
    }
  }
}


- (void) scrollWheel: (NSEvent *)theEvent {
  scrollWheelDelta += [theEvent deltaY];
  
  if (scrollWheelDelta > 0) {
    if ([pathModelView selectionSticksToEndPoint]) {
      // Keep it at zero, to make moving up not unnecessarily cumbersome.
      scrollWheelDelta = 0;
    }
    else if (scrollWheelDelta > SCROLL_WHEEL_SENSITIVITY + 0.5f) {
      if ([pathModelView canMoveSelectionDown]) {
        [pathModelView moveSelectionDown];
      }
      else {
        [pathModelView setSelectionSticksToEndPoint: YES];
      }

      // Make it easy to move up down again.
      scrollWheelDelta = - SCROLL_WHEEL_SENSITIVITY;
    }
  }
  else {
    if (! [pathModelView canMoveSelectionUp]) {
      // Keep it at zero, to make moving up not unnecessarily cumbersome.
      scrollWheelDelta = 0;
    }
    else if (scrollWheelDelta < - (SCROLL_WHEEL_SENSITIVITY + 0.5f)) {
      [pathModelView moveSelectionUp];

      // Make it easy to move back down again.
      scrollWheelDelta = SCROLL_WHEEL_SENSITIVITY;
    }
  }
}


- (void) mouseDown: (NSEvent *)theEvent {
  // Toggle the path locking.

  BOOL  wasLocked = [[pathModelView pathModel] isVisiblePathLocked];
  if (wasLocked) {
    // Unlock first, then build new path.
    [[pathModelView pathModel] setVisiblePathLocking: NO];
  }

  NSPoint  loc = [theEvent locationInWindow];
  [self updateSelectedItem: [self convertPoint: loc fromView: nil]];

  if (!wasLocked) {
    // Now lock, after having updated path.

    if ([pathModelView isSelectedFileItemVisible]) {
      // Only lock the path if it contains the selected item, i.e. if the 
      // mouse click was inside the visible tree.
      [[pathModelView pathModel] setVisiblePathLocking: YES];
    }
  }
}


- (void) mouseMoved: (NSEvent *)theEvent {
  if ([[pathModelView pathModel] isVisiblePathLocked]) {
    // Ignore mouseMoved events the the item path is locked.
    //
    // Note: Although this view stops accepting mouse moved events when the
    // path becomes locked, these may be generated later on anyway, requested
    // by other components. In particular, mousing over the NSTextViews in the
    // drawer triggers mouse moved events again.
    return;
  }
  
  NSPoint  loc = [[self window] mouseLocationOutsideOfEventStream];
  // Note: not using the location returned by [theEvent locationInWindow] as
  // this is incorrect after the drawer has been clicked on.

  NSPoint  mouseLoc = [self convertPoint: loc fromView: nil];
  BOOL isInside = [self mouse: mouseLoc inRect: [self bounds]];

  if (isInside) {
    [self updateSelectedItem: mouseLoc];
  }
  else {
    [[pathModelView pathModel] clearVisiblePath];
  }
}

@end // @implementation DirectoryView


@implementation DirectoryView (PrivateMethods)

- (void) forceRedraw {
  [self setNeedsDisplay: YES];

  // Discard the existing image.
  [treeImage release];
  treeImage = nil;
}


/**
 * Callback method that signals that the drawing task has finished execution.
 * It is also called when the drawing has been aborted, in which the image 
 * will be nil.
 */
- (void) itemTreeImageReady: (id) image {
  if (image != nil) {
    // Only take action when the drawing task has completed succesfully. 
    //
    // Without this check, a race condition can occur. When a new drawing task
    // aborts the execution of an ongoing task, the completion of the latter
    // and subsequent invocation of -drawRect: results in the abortion of
    // the new task (as long as it has not yet completed).
  
    // Note: This method is called from the main thread (even though it has been
    // triggered by the drawer's background thread). So calling setNeedsDisplay
    // directly is okay.
    [treeImage release];
    treeImage = [image retain];
  
    [self setNeedsDisplay: YES];
  }
}


- (void) postColorPaletteChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: ColorPaletteChangedEvent object: self];
}

- (void) postColorMappingChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: ColorMappingChangedEvent object: self];
}


/* Called when selection changes in path
 */
- (void) selectedItemChanged: (NSNotification *)notification {
  [self setNeedsDisplay: YES];
}

- (void) visibleTreeChanged: (NSNotification *)notification {
  [self forceRedraw];
}

- (void) visiblePathLockingChanged: (NSNotification *)notification {
  BOOL  locked = [[pathModelView pathModel] isVisiblePathLocked];
  
  // Update the item path drawer directly. Although the drawer could also
  // listen to the notification, it seems better to do it like this. It keeps
  // the item path drawer more general, and as the item path drawer is tightly
  // integrated with this view, there is no harm in updating it directly.
  [pathDrawer setHighlightPathEndPoint: locked];
 
  [[self window] setAcceptsMouseMovedEvents: 
                   !locked && [[self window] isMainWindow]];
  
  [self setNeedsDisplay: YES];
}

- (void) windowMainStatusChanged: (NSNotification *)notification {
  [[self window] setAcceptsMouseMovedEvents: 
                   ![[pathModelView pathModel] isVisiblePathLocked] && 
                   [[self window] isMainWindow]];
}


- (void) observeColorMapping {
  ItemTreeDrawerSettings  *treeDrawerSettings = [self treeDrawerSettings];
  NSObject <FileItemMappingScheme>  *colorMapping = 
    [[treeDrawerSettings colorMapper] fileItemMappingScheme];
    
  if (colorMapping != observedColorMapping) {
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
    
    if (observedColorMapping != nil) {
      [nc removeObserver: self name: MappingSchemeChangedEvent 
            object: observedColorMapping];
      [observedColorMapping release];
    }

    [nc addObserver: self selector: @selector(colorMappingChanged:)
          name: MappingSchemeChangedEvent object: colorMapping];
    observedColorMapping = [colorMapping retain];
  }
}

- (void) colorMappingChanged: (NSNotification *) notification {
  // Replace the mapper that is used by a new one (still from the same scheme)
  [self setTreeDrawerSettings: 
         [[self treeDrawerSettings] copyWithColorMapper: 
                                      [observedColorMapping fileItemMapping]]];

  [self postColorMappingChanged];   
}


- (void) updateSelectedItem: (NSPoint) point {
  [pathModelView selectItemAtPoint: point 
                   startingAtTree: [self treeInView]
                   usingLayoutBuilder: layoutBuilder 
                   bounds: [self bounds]];
  // Redrawing in response to any changes will happen when the change 
  // notification is received.
}

@end // @implementation DirectoryView (PrivateMethods)
