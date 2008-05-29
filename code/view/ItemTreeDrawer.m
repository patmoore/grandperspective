#import "ItemTreeDrawer.h"

#import "DirectoryItem.h"
#import "FileItemMapping.h"
#import "TreeLayoutBuilder.h"
#import "FileItemPathStringCache.h"
#import "ItemTreeDrawerSettings.h"
#import "FileItemTest.h"
#import "TreeContext.h"


@implementation ItemTreeDrawer

- (id) init {
  ItemTreeDrawerSettings  *defaultSettings = 
    [[[ItemTreeDrawerSettings alloc] init] autorelease];
    
  return [self initWithTreeDrawerSettings: defaultSettings];
}

// Overrides designated initialiser
- (id) initWithColorPalette: (NSColorList *)colorPaletteVal {
  ItemTreeDrawerSettings  *defaultSettings = 
    [[[ItemTreeDrawerSettings alloc] init] autorelease];
    
  ItemTreeDrawerSettings  *settings =
    [defaultSettings copyWithColorPalette: colorPaletteVal];
    
  return [self initWithTreeDrawerSettings: settings];
}

- (id) initWithTreeDrawerSettings: (ItemTreeDrawerSettings *)settings {
  if (self = [super initWithColorPalette: [settings colorPalette]]) {
    // Make sure values are nil before calling updateSettings. 
    colorMapper = nil;
    fileItemMask = nil;
    
    [self updateSettings: settings];
    
    fileItemPathStringCache = [[FileItemPathStringCache alloc] init];
    [fileItemPathStringCache setAddTrailingSlashToDirectoryPaths: YES];
    
    freeSpaceColor = [self intValueForColor: [NSColor blackColor]];
    usedSpaceColor = [self intValueForColor: [NSColor darkGrayColor]];
    visibleTreeBackgroundColor = [self intValueForColor: [NSColor grayColor]];
    
    abort = NO;
  }
  return self;
}

- (void) dealloc {
  [colorMapper release];
  [fileItemMask release];
  
  [fileItemPathStringCache release];
  
  NSAssert(visibleTree==nil, @"visibleTree should be nil.");

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


- (void) setFileItemMask:(NSObject <FileItemTest> *)fileItemMaskVal {
  if (fileItemMaskVal != fileItemMask) {
    [fileItemMask release];
    fileItemMask = [fileItemMaskVal retain];
  }
}

- (NSObject <FileItemTest> *) fileItemMask {
  return fileItemMask;
}


- (void) setShowPackageContents: (BOOL) showPackageContentsVal {
  showPackageContents = showPackageContentsVal;
}

- (BOOL) showPackageContents {
  return showPackageContents;
}


- (void) updateSettings: (ItemTreeDrawerSettings *)settings {
  [self setColorMapper: [settings colorMapper]];
  [self setColorPalette: [settings colorPalette]];
  [self setFileItemMask: [settings fileItemMask]];
  [self setShowPackageContents: [settings showPackageContents]];
}


- (NSImage *) drawImageOfVisibleTree: (FileItem *)visibleTreeVal
                startingAtTree: (FileItem *)treeRoot
                usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
                inRect: (NSRect) bounds {
  NSDate  *startTime = [NSDate date];
  
  [self setupBitmap: bounds];
  
  insideVisibleTree = NO;
  NSAssert(visibleTree == nil, @"visibleTree should be nil.");
  visibleTree = visibleTreeVal; 
                     // Not retaining it. It is only needed during this method.

  // TODO: cope with fact when bounds not start at (0, 0)? Would this every be
  // useful/occur?
  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];
  visibleTree = nil;
   
  [fileItemPathStringCache clearCache];

  if (!abort) {
    // NSLog(@"Done drawing. Time taken=%f", -[startTime timeIntervalSinceNow]);
    
    return [self createImageFromBitmap];
  }
  else {
    abort = NO; // Enable drawer again for next time.

    [drawBitmap release];
    drawBitmap = nil;
    
    return nil;
  }
}


- (void) abortDrawing {
  abort = YES;
}


- (BOOL) descendIntoItem: (Item *)item atRect: (NSRect) rect 
           depth: (int) depth {
  if ( [item isVirtual] ) {
    return YES;
  }
  
  FileItem*  file = (FileItem*)item;
    
  if ( file == visibleTree ) {
    insideVisibleTree = YES;
      
    [self drawBasicFilledRect: rect intColor: visibleTreeBackgroundColor];
  }
    
  if (!showPackageContents && [file isDirectory]) {
    // Package contents should not be shownn. If the directory is a package
    // replace it with a file item.
      
    file = [(DirectoryItem *)file itemWhenHidingPackageContents];
  }
    
  if (! [file isSpecial] 
      && fileItemMask != nil 
      && [fileItemMask testFileItem: file context: fileItemPathStringCache]) {
    // Item is masked
    return NO;
  }
    
  if ( [file isDirectory] ) {
    if ( [file isSpecial] && [[file name] isEqualToString: UsedSpace] ) {
      [self drawBasicFilledRect: rect intColor: usedSpaceColor];
    }
    
    if ( !insideVisibleTree ) {
      // Do not descend if the DirectoryItem "file" is not an ancestor of the
      // visible tree.
      if (![file isAncestorOfFileItem: visibleTree]) {
        return NO;
      }
    }
    
    // Descend unless drawing has been aborted
    return !abort;
  }

  // It's a plain file
  if ( [file isSpecial] && [[file name] isEqualToString: FreeSpace] ) {
    [self drawBasicFilledRect: rect intColor: freeSpaceColor];
  }
  else if ( insideVisibleTree ) {
    if ( [file isSpecial] ) {
      if ( [[file name] isEqualToString: FreedSpace] ) {
        [self drawBasicFilledRect: rect intColor: freeSpaceColor];
      }
    }
    else {
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
  }

  // Cannot descend from a file, so return NO to save having to check this.
  return NO;
}


- (void) emergedFromItem: (Item *)item {
  if (item == visibleTree) {
    insideVisibleTree = NO;
  }
}

@end // @implementation ItemTreeDrawer
