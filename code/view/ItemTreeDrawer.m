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


- (void) updateSettings: (ItemTreeDrawerSettings *)settings {
  [self setColorMapper: [settings colorMapper]];
  [self setColorPalette: [settings colorPalette]];
  [self setFileItemMask: [settings fileItemMask]];
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
  BOOL  descend = YES; // Default 
           
  if (![item isVirtual]) {
    FileItem*  file = (FileItem*)item;
    
    if (file==visibleTree) {
      insideVisibleTree = YES;
      
      [self drawBasicFilledRect: rect intColor: visibleTreeBackgroundColor];
    }
    
    if ([file isPlainFile]) {
      if ([file isSpecial] && [[file name] isEqualToString: FreeSpace]) {
        [self drawBasicFilledRect: rect intColor: freeSpaceColor];
      }
      else if (insideVisibleTree) {
        if ([file isSpecial]) {
          if ([[file name] isEqualToString: FreedSpace]) {
            [self drawBasicFilledRect: rect intColor: freeSpaceColor];
          }
        }
        else if ( fileItemMask==nil 
                  || [fileItemMask testFileItem: file 
                                     context: fileItemPathStringCache] ) {
          int  colorIndex = [colorMapper hashForFileItem: (PlainFileItem *)file 
                                           atDepth: depth];
          if ([colorMapper canProvideLegend]) {
            NSAssert(colorIndex >= 0, @"Negative hash value.");
            colorIndex = MIN(colorIndex, numGradientColors - 1);
          }
          else {
            colorIndex = abs(colorIndex) % numGradientColors;
          }

          [self drawGradientFilledRect: rect colorIndex: colorIndex];
        }
      }
    }
    else {
      if ([file isSpecial] && [[file name] isEqualToString: UsedSpace]) {
        [self drawBasicFilledRect: rect intColor: usedSpaceColor];
      }
    
      if (!insideVisibleTree) {
        // Check if the DirectoryItem "file" is an ancestor of the visible
        // tree. If not, there's no need to descend.
        FileItem  *ancestor = visibleTree;
        BOOL  isAncestor = NO;
        while (ancestor = [ancestor parentDirectory]) {
          if (file == ancestor) {
            isAncestor = YES;
            break;
          }
        }
        if (!isAncestor) {
          descend = NO;
        }
      }
    }
  }

  if (abort) {
    descend = NO;
  }
  
  return descend;
}

- (void) emergedFromItem: (Item *)item {
  if (item == visibleTree) {
    insideVisibleTree = NO;
  }
}

@end // @implementation ItemTreeDrawer
