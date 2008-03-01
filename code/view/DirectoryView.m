#import "DirectoryView.h"

#import "math.h"

#import "DirectoryItem.h"

#import "TreeLayoutBuilder.h"
#import "ItemTreeDrawer.h"
#import "ItemTreeDrawerSettings.h"
#import "ItemPathDrawer.h"
#import "ItemPathBuilder.h"
#import "ItemPathModel.h"

#import "TreeLayoutTraverser.h"

#import "AsynchronousTaskManager.h"
#import "DrawTaskExecutor.h"
#import "DrawTaskInput.h"

#import "FileItemHashing.h"
#import "FileItemHashingScheme.h"


#define SCROLL_WHEEL_SENSITIVITY  6.0


NSString  *ColorPaletteChangedEvent = @"colorPaletteChanged";
NSString  *ColorMappingChangedEvent = @"colorMappingChanged";


@interface DirectoryView (PrivateMethods)

- (void) forceRedraw;

- (void) itemTreeImageReady: (id) image;

// Sends selection-changed events, which comprise selection-changes inside
// the path, as well as selection of "invisible" items outside the path.
- (void) postSelectedItemChanged;

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
    pathBuilder = [[ItemPathBuilder alloc] init];
    
    invisibleSelectedItem = nil;
    
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
  [pathBuilder release];
  
  [observedColorMapping release];
  
  [pathModel release];
  [invisibleSelectedItem release];
  
  [treeImage release];
  
  [super dealloc];
}


- (void) postInitWithPathModel: (ItemPathModel *)pathModelVal {
  NSAssert(pathModel==nil, @"The item path model should only be set once.");

  pathModel = [pathModelVal retain];
  
  DrawTaskExecutor  *drawTaskExecutor = 
    [[DrawTaskExecutor alloc] initWithTreeContext: [pathModel treeContext]];
  drawTaskManager = 
    [[AsynchronousTaskManager alloc] initWithTaskExecutor: drawTaskExecutor];
  [drawTaskExecutor release];
  [self observeColorMapping];
  
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  [nc addObserver: self selector: @selector(selectedItemChanged:)
        name: SelectedItemChangedEvent object: pathModel];
  [nc addObserver: self selector: @selector(visibleTreeChanged:)
        name: VisibleTreeChangedEvent object: pathModel];
  [nc addObserver: self selector: @selector(visiblePathLockingChanged:)
        name: VisiblePathLockingChangedEvent object: pathModel];
          
  [nc addObserver: self selector: @selector(windowMainStatusChanged:)
        name: NSWindowDidBecomeMainNotification object: [self window]];
  [nc addObserver: self selector: @selector(windowMainStatusChanged:)
        name: NSWindowDidResignMainNotification object: [self window]];
  
  [self visiblePathLockingChanged: nil];
  [self setNeedsDisplay: YES];
}


- (ItemPathModel *)itemPathModel {
  return pathModel;
}

- (FileItem *)treeInView {
  return showEntireVolume ? [pathModel volumeTree] : [pathModel visibleTree];
}

- (FileItem *)selectedItem {
  return (invisibleSelectedItem != nil) 
            ? invisibleSelectedItem : [pathModel selectedFileItem];
  // TODO: Return "nil" when the selected item is the visible tree root and
  // the path is not locked?
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
  if (pathModel==nil) {
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
      [[DrawTaskInput alloc] initWithVisibleTree: [pathModel visibleTree] 
                               treeInView: [self treeInView]
                               layoutBuilder: layoutBuilder
                               bounds: [self bounds]];
    [drawTaskManager asynchronouslyRunTaskWithInput: drawInput callback: self 
                       selector: @selector(itemTreeImageReady:)];
    [drawInput release];
  }
  else {
    [treeImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];

    if (invisibleSelectedItem == nil) {
      [pathDrawer drawVisiblePath: pathModel
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
    if (! [pathModel selectionSticksToEndPoint]) {
      if ([pathModel canMoveSelectionDown]) {
        [pathModel moveSelectionDown];
      }
      else {
        [pathModel setSelectionSticksToEndPoint: YES];
      }
    }
  }
  else if ([chars isEqualToString: @"["]) {
    if ([pathModel canMoveSelectionUp]) {
      [pathModel moveSelectionUp];
    }
  }
}


- (void) scrollWheel: (NSEvent *)theEvent {
  scrollWheelDelta += [theEvent deltaY];
  
  if (scrollWheelDelta > 0) {
    if ([pathModel selectionSticksToEndPoint]) {
      // Keep it at zero, to make moving up not unnecessarily cumbersome.
      scrollWheelDelta = 0;
    }
    else if (scrollWheelDelta > SCROLL_WHEEL_SENSITIVITY + 0.5f) {
      if ([pathModel canMoveSelectionDown]) {
        [pathModel moveSelectionDown];
      }
      else {
        [pathModel setSelectionSticksToEndPoint: YES];
      }

      // Make it easy to move up down again.
      scrollWheelDelta = - SCROLL_WHEEL_SENSITIVITY;
    }
  }
  else {
    if (! [pathModel canMoveSelectionUp]) {
      // Keep it at zero, to make moving up not unnecessarily cumbersome.
      scrollWheelDelta = 0;
    }
    else if (scrollWheelDelta < - (SCROLL_WHEEL_SENSITIVITY + 0.5f)) {
      [pathModel moveSelectionUp];

      // Make it easy to move back down again.
      scrollWheelDelta = SCROLL_WHEEL_SENSITIVITY;
    }
  }
}


- (void) mouseDown: (NSEvent *)theEvent {
  // Toggle the path locking.

  BOOL  wasLocked = [pathModel isVisiblePathLocked];
  if (wasLocked) {
    // Unlock first, then build new path.
    [pathModel setVisiblePathLocking: NO];
  }

  NSPoint  loc = [theEvent locationInWindow];
  [self updateSelectedItem: [self convertPoint: loc fromView: nil]];

  if (!wasLocked) {
    // Now lock, after having updated path.

    if (invisibleSelectedItem == nil) {
      // Only lock the path if it contains the selected item, i.e. if the 
      // mouse click was inside the visible tree.
      [pathModel setVisiblePathLocking: YES];
    }
  }
}


- (void) mouseMoved: (NSEvent *)theEvent {
  if ([pathModel isVisiblePathLocked]) {
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
    [pathModel clearVisiblePath];
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


- (void) itemTreeImageReady: (id) image {
  // Note: This method is called from the main thread (even though it has been
  // triggered by the drawer's background thread). So calling setNeedsDisplay
  // directly is okay.
  [treeImage release];
  treeImage = [image retain];
  
  [self setNeedsDisplay: YES];  
}


- (void) postSelectedItemChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: SelectedItemChangedEvent object: self];
}

- (void) postColorPaletteChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: ColorPaletteChangedEvent object: self];
}

- (void) postColorMappingChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: ColorMappingChangedEvent object: self];
}


// Called when selection changes in path
- (void) selectedItemChanged: (NSNotification *)notification {
  [self setNeedsDisplay: YES];
  
  if (invisibleSelectedItem != nil) {
    // Set the view's selected item to that of the path.
    [invisibleSelectedItem release]; 
    invisibleSelectedItem = nil;
  }
  
  // Propagate event to my listeners.
  [self postSelectedItemChanged];
}

- (void) visibleTreeChanged: (NSNotification *)notification {
  [self forceRedraw];
}

- (void) visiblePathLockingChanged: (NSNotification *)notification {
  BOOL  locked = [pathModel isVisiblePathLocked];
  
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
                   ![pathModel isVisiblePathLocked] && 
                   [[self window] isMainWindow]];
}



- (void) observeColorMapping {
  ItemTreeDrawerSettings  *treeDrawerSettings = [self treeDrawerSettings];
  NSObject <FileItemHashingScheme>  *colorMapping = 
    [[treeDrawerSettings colorMapper] fileItemHashingScheme];
    
  if (colorMapping != observedColorMapping) {
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
    
    if (observedColorMapping != nil) {
      [nc removeObserver: self name: HashingSchemeChangedEvent 
            object: observedColorMapping];
      [observedColorMapping release];
    }

    [nc addObserver: self selector: @selector(colorMappingChanged:)
          name: HashingSchemeChangedEvent object: colorMapping];
    observedColorMapping = [colorMapping retain];
  }
}

- (void) colorMappingChanged: (NSNotification *) notification {
  // Replace the mapper that is used by a new one (still from the same scheme)
  [self setTreeDrawerSettings: 
         [[self treeDrawerSettings] copyWithColorMapper: 
                                      [observedColorMapping fileItemHashing]]];

  [self postColorMappingChanged];   
}


// Updates the selected item as well as the path, so that the path points to 
// it (if possible). This may not possible when the entire volume is shown, as
// the selected item can be outside the visible tree.
- (void) updateSelectedItem: (NSPoint) point {
  FileItem  *oldInvisibleSelectedItem = invisibleSelectedItem;

  FileItem  *selectedItem =
    [pathBuilder selectItemAtPoint: point 
                   startingAtTree: [self treeInView]
                   usingLayoutBuilder: layoutBuilder 
                   bounds: [self bounds]
                   updatePath: pathModel];
                   
  if (selectedItem != [pathModel selectedFileItem]) {
    // The selected item is outside the visible tree. It must therefore be
    // maintained by the view
    
    NSAssert([pathModel selectedFileItem] == [pathModel visibleTree], 
               @"Unexpected pathModel state.");
    
    [invisibleSelectedItem release];
    invisibleSelectedItem = [selectedItem retain];
    
    if (oldInvisibleSelectedItem == nil) {
      // There was a visible selected item. Not anymore, so redraw the view.
      [self setNeedsDisplay: YES];
    }
  }
  else {
    // The selected item is inside the visible tree. It therefore managed by
    // the pathModel (so that it can be moved up/down the path)
    [invisibleSelectedItem release]; 
    invisibleSelectedItem = nil;
  }
  
  if (oldInvisibleSelectedItem != invisibleSelectedItem) {
    // Only post changes here to the invisible item. When the selected item
    // in the path changed, -selectedItemChanged will be notified and post the 
    // event in response. 
    [self postSelectedItemChanged];
  }
}

@end // @implementation DirectoryView (PrivateMethods)
