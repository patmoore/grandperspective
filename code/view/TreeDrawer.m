#import "TreeDrawer.h"

#import "DirectoryItem.h"
#import "FileItemMapping.h"
#import "TreeLayoutBuilder.h"
#import "FilteredTreeGuide.h"
#import "TreeDrawerSettings.h"
#import "TreeContext.h"


@implementation TreeDrawer

// Overrides designated initialiser
- (id) initWithColorPalette: (NSColorList *)colorPaletteVal {
  NSAssert(NO, @"Use initWithScanTree: instead.");
}

- (id) initWithScanTree: (DirectoryItem *)scanTreeVal {
  TreeDrawerSettings  *defaultSettings = 
    [[[TreeDrawerSettings alloc] init] autorelease];
    
  return [self initWithScanTree: scanTreeVal 
                 treeDrawerSettings: defaultSettings];
}

- (id) initWithScanTree: (DirectoryItem *)scanTreeVal 
         treeDrawerSettings: (TreeDrawerSettings *)settings {
  if (self = [super initWithColorPalette: [settings colorPalette]]) {
    scanTree = [scanTreeVal retain];
  
    // Make sure values are set before calling updateSettings. 
    colorMapper = nil;
    treeGuide = [[FilteredTreeGuide alloc] init];
    
    [self updateSettings: settings];
    
    freeSpaceColor = [self intValueForColor: [NSColor blackColor]];
    usedSpaceColor = [self intValueForColor: [NSColor darkGrayColor]];
    visibleTreeBackgroundColor = [self intValueForColor: [NSColor grayColor]];
    
    abort = NO;
  }
  return self;
}

- (void) dealloc {
  [colorMapper release];
  [treeGuide release];

  [scanTree release];

  NSAssert(visibleTree==nil, @"visibleTree should be nil.");
  [visibleTree release]; // For sake of completeness. Can be omitted.
  
  [super dealloc];
}


- (void) setColorMapper: (NSObject <FileItemMapping> *)colorMapperVal {
  NSAssert(colorMapperVal != nil, @"Cannot set an invalid color mapper.");

  if (colorMapperVal != colorMapper) {
    [colorMapper release];
    colorMapper = [colorMapperVal retain];
  }
}

- (NSObject <FileItemMapping> *) colorMapper {
  return colorMapper;
}


- (void) setFileItemMask:(NSObject <FileItemTest> *)maskTest {
  [treeGuide setFileItemTest: maskTest];
}

- (NSObject <FileItemTest> *) fileItemMask {
  return [treeGuide fileItemTest];
}


- (void) setShowPackageContents: (BOOL) showPackageContents {
  [treeGuide setPackagesAsFiles: !showPackageContents];
}

- (BOOL) showPackageContents {
  return ! [treeGuide packagesAsFiles];
}


- (void) updateSettings: (TreeDrawerSettings *)settings {
  [self setColorMapper: [settings colorMapper]];
  [self setColorPalette: [settings colorPalette]];
  [self setColorGradient: [settings colorGradient]];
  [self setFileItemMask: [settings fileItemMask]];
  [self setShowPackageContents: [settings showPackageContents]];
}


- (NSImage *) drawImageOfVisibleTree: (FileItem *)visibleTreeVal
                startingAtTree: (FileItem *)treeRoot
                usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
                inRect: (NSRect) bounds {
  [self setupBitmap: bounds];
  
  insideVisibleTree = NO;
  NSAssert(visibleTree == nil, @"visibleTree should be nil.");
  visibleTree = [visibleTreeVal retain]; 

  // TODO: cope with fact when bounds not start at (0, 0)? Would this every be
  // useful/occur?
  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];

  [visibleTree release];
  visibleTree = nil;

  if ( !abort ) {
    return [self createImageFromBitmap];
  }
  else {
    [drawBitmap release];
    drawBitmap = nil;
    
    return nil;
  }
}


- (void) clearAbortFlag {
  abort = NO;
}

- (void) abortDrawing {
  abort = YES;
}


- (BOOL) descendIntoItem: (Item *)item atRect: (NSRect) rect 
           depth: (int) depth {
  if ( [item isVirtual] ) {
    return YES;
  }
  
  FileItem  *file = (FileItem *)item;
  
  if ( file == visibleTree ) {
    insideVisibleTree = YES;
      
    [self drawBasicFilledRect: rect intColor: visibleTreeBackgroundColor];
    
    // Check if any ancestors are masked
    FileItem  *ancestor = file;
    while (ancestor != scanTree) {
      ancestor = [ancestor parentDirectory];
      if (! [treeGuide includeFileItem: ancestor]) {
        return NO;
      }
    }
  }
    
  if ( !insideVisibleTree ) {
    // Not yet inside the visible tree (implying that the entire volume is 
    // shown). Ensure that the special "volume" items are drawn, and only
    // descend towards the visible tree. 
  
    if ( [file isDirectory] ) {
      if ( ![file isPhysical] && [[file name] isEqualToString: UsedSpace] ) {
        [self drawBasicFilledRect: rect intColor: usedSpaceColor];
      }
      
      if ( [file isAncestorOfFileItem: visibleTree] ) {
        [treeGuide descendIntoDirectory: (DirectoryItem *)file];
        return YES;
      }
      else {
        return NO;
      }
    }
    else {
      if ( ![file isPhysical] && [[file name] isEqualToString: FreeSpace] ) {
        [self drawBasicFilledRect: rect intColor: freeSpaceColor];
      }
      
      return NO;
    }
  }
  
  // Inside the visible tree. Check if the item is masked
  file = [treeGuide includeFileItem: file];
  if (file == nil) {
    return NO;
  }
    
  if ( [file isDirectory] ) {
    // Descend unless drawing has been aborted
    
    if ( !abort ) {
      [treeGuide descendIntoDirectory: (DirectoryItem *)file];
      return YES;
    }
    else {
      return NO;
    }
  }

  // It's a plain file
  if ( [file isPhysical] ) {
    int  colorIndex = [colorMapper hashForFileItem: (PlainFileItem *)file 
                                     atDepth: depth];
    if ( [colorMapper canProvideLegend] ) {
      NSAssert(colorIndex >= 0, @"Negative hash value.");
      colorIndex = MIN(colorIndex, numGradientColors - 1);
    }
    else {
      colorIndex = abs(colorIndex) % numGradientColors;
    }

    [self drawGradientFilledRect: rect colorIndex: colorIndex];
  }
  else {
    if ( [[file name] isEqualToString: FreedSpace] ) {
      [self drawBasicFilledRect: rect intColor: freeSpaceColor];
    }
  }

  if (item == visibleTree) {
    // Note: emergedFromItem: will not be invoked, so unset the flag here.
    insideVisibleTree = NO;
  }

  // Do not descend into the item. 
  //
  // Note: This is not just an optimisation but needs to be done. Even though 
  // the item is seen as a file by the TreeDrawer, it may actually be a 
  // package whose contents are hidden. The TreeLayoutBuilder should not 
  // descend into the directory in this case.
  return NO;
}

- (void) emergedFromItem: (Item *)item {
  if ( ! [item isVirtual] ) {
    if (item == visibleTree) {
      insideVisibleTree = NO;
    }
  
    if ( [((FileItem *)item) isDirectory] ) {
      [treeGuide emergedFromDirectory: (DirectoryItem *)item];
    }
  }
}

@end // @implementation TreeDrawer
