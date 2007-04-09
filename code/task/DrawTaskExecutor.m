#import "DrawTaskExecutor.h"

#import "FileItem.h"
#import "ItemTreeDrawer.h"
#import "DrawTaskInput.h"
#import "FileItemHashing.h"
#import "TreeLayoutBuilder.h"

@implementation DrawTaskExecutor

// Overrides designated initialiser
- (id) init {
  return [self initWithTreeDrawer:[[[ItemTreeDrawer alloc] init] autorelease]];
}

- (id) initWithTreeDrawer:(ItemTreeDrawer*)treeDrawerVal {
  if (self = [super init]) {
    treeDrawer = [treeDrawerVal retain];
    showFreeSpace = [[treeDrawer treeLayoutBuilder] showFreeSpace];
    colorMapping = [[treeDrawer colorMapping] retain];
    colorPalette = [[treeDrawer colorPalette] retain];
    fileItemMask = [[treeDrawer fileItemMask] retain];

    enabled = YES;
  }
  return self;
}

- (void) dealloc {
  [treeDrawer release];
  
  [colorMapping release];
  [colorPalette release];
  [fileItemMask release];
  
  [super dealloc];
}


- (void) setShowFreeSpace: (BOOL) showFreeSpaceVal {
  showFreeSpace = showFreeSpaceVal;
}

- (BOOL) showFreeSpace {
  return showFreeSpace;
}


- (void) setColorMapping: (FileItemHashing *)colorMappingVal {
  if (colorMappingVal != colorMapping) {
    [colorMapping release];
    colorMapping = [colorMappingVal retain];
  }
}

- (FileItemHashing *) colorMapping {
  return colorMapping;
}


- (void) setColorPalette: (NSColorList *)colorPaletteVal {
  if (colorPaletteVal != colorPalette) {
    [colorPalette release];
    colorPalette = [colorPaletteVal retain];
  }
}

- (NSColorList *) colorPalette {
  return colorPalette;
}


- (void) setFileItemMask: (NSObject <FileItemTest> *)fileItemMaskVal {
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
    [[treeDrawer treeLayoutBuilder] setShowFreeSpace: showFreeSpace];
    [treeDrawer setColorMapping: colorMapping];
    [treeDrawer setColorPalette: colorPalette];
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
