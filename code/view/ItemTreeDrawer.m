#import "ItemTreeDrawer.h"

#import "DirectoryItem.h"
#import "FileItemHashing.h"
#import "TreeLayoutBuilder.h"
#import "FileItemPathStringCache.h"
#import "ItemTreeDrawerSettings.h"
#import "FileItemTest.h"
#import "TreeBuilder.h"


@interface ItemTreeDrawer (PrivateMethods)

- (UInt32) intValueForColor: (NSColor *)color;

- (void) drawBasicFilledRect: (NSRect) rect intColor: (UInt32) intColor;

- (void) drawGradientFilledRect:(NSRect)rect colorHash:(int)hash;
- (void) initGradientColors;

@end


@implementation ItemTreeDrawer

- (id) init {
 return 
    [self initWithTreeDrawerSettings: 
            [[[ItemTreeDrawerSettings alloc] init] autorelease]];
}

- (id) initWithTreeDrawerSettings: (ItemTreeDrawerSettings *)settings {
  if (self = [super init]) {
    // Make sure values are nil before calling updateSettings. 
    colorMapping = nil;
    colorPalette = nil;
    fileItemMask = nil;
    
    [self updateSettings: settings];
    
    fileItemPathStringCache = [[FileItemPathStringCache alloc] init];
    [fileItemPathStringCache setAddTrailingSlashToDirectoryPaths: YES];
    
    freeSpaceColor = [self intValueForColor: [NSColor darkGrayColor]];
    usedSpaceColor = [self intValueForColor: [NSColor grayColor]];
    
    abort = NO;
  }
  return self;
}

- (void) dealloc {
  [colorMapping release];
  [colorPalette release];
  [fileItemMask release];
  
  [fileItemPathStringCache release];
  
  free(gradientColors);
  
  NSAssert(visibleTree==nil, @"visibleTree should be nil.");
  NSAssert(drawBitmap==nil, @"Bitmap should be nil.");
  
  [super dealloc];
}


- (void) setColorMapping: (FileItemHashing *)colorMappingVal {
  NSAssert(colorMappingVal != nil, 
           @"Cannot set an invalid color mapping.");

  if (colorMappingVal != colorMapping) {
    [colorMapping release];
    colorMapping = [colorMappingVal retain];
  }
}

- (FileItemHashing *) colorMapping {
  return colorMapping;
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


- (void) setColorPalette: (NSColorList *)colorPaletteVal {
  NSAssert(colorPaletteVal != nil && [[colorPaletteVal allKeys] count] > 0,
           @"Cannot set an invalid color palette.");

  if (colorPaletteVal != colorPalette) {
    [colorPalette release];
    colorPalette = [colorPaletteVal retain];

    initGradientColors = YES;
  }
}

- (NSColorList *) colorPalette {
  return colorPalette;
}


- (void) updateSettings: (ItemTreeDrawerSettings *)settings {
  [self setColorMapping: [settings colorMapping]];
  [self setColorPalette: [settings colorPalette]];
  [self setFileItemMask: [settings fileItemMask]];
}


- (NSImage *) drawImageOfVisibleTree: (FileItem *)visibleTreeVal
                startingAtTree: (FileItem *)treeRoot
                usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
                inRect: (NSRect) bounds {
  NSDate  *startTime = [NSDate date];
  
  NSAssert(drawBitmap == nil, @"Bitmap should be nil.");
  drawBitmap =  
    [[NSBitmapImageRep alloc] 
      initWithBitmapDataPlanes: NULL
      pixelsWide: (int)bounds.size.width
      pixelsHigh: (int)bounds.size.height
      bitsPerSample: 8
      samplesPerPixel: 3
      hasAlpha: NO
      isPlanar: NO
      colorSpaceName: NSDeviceRGBColorSpace
      bytesPerRow: 0
      bitsPerPixel: 32];

  if (initGradientColors) {
    [self initGradientColors];
    initGradientColors = NO;
  }
  
  insideVisibleTree = NO;
  NSAssert(visibleTree == nil, @"visibleTree should be nil.");
  visibleTree = visibleTreeVal; 
                     // Not retaining it. It is only needed during this method.

  // TODO: cope with fact when bounds not start at (0, 0)? Would this every be
  // useful/occur?
  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];
  visibleTree = nil;
   
  [fileItemPathStringCache clearCache];

  NSImage  *image = nil;

  if (!abort) {
    NSLog(@"Done drawing. Time taken=%f", -[startTime timeIntervalSinceNow]);

    image = [[[NSImage alloc] initWithSize:bounds.size] autorelease];
    [image addRepresentation: drawBitmap];
  }
  abort = NO; // Enable drawer again for next time.

  [drawBitmap release];
  drawBitmap = nil;

  return image;
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
    }
    
    if ([file isPlainFile]) {
      if ([file isSpecial] && [[file name] isEqualToString: FreeSpace]) {
        [self drawBasicFilledRect: rect intColor: freeSpaceColor];
      }
    
      if (insideVisibleTree) {
        if ( fileItemMask==nil 
             || [fileItemMask testFileItem: file 
                                context: fileItemPathStringCache] ) {
          [self drawGradientFilledRect: rect 
                  colorHash: [colorMapping hashForFileItem: file depth: depth]];
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


@implementation ItemTreeDrawer (PrivateMethods)

- (UInt32) intValueForColor: (NSColor *)color {
  color = [color colorUsingColorSpaceName: NSDeviceRGBColorSpace];
  return CFSwapInt32BigToHost(
                 ((UInt32)([color redComponent] * 255) & 0xFF) << 24 |
                 ((UInt32)([color greenComponent] * 255) & 0xFF) << 16 |
                 ((UInt32)([color blueComponent] * 255) & 0xFF) << 8);
}


- (void) drawBasicFilledRect: (NSRect) rect intColor: (UInt32) intColor {
  UInt32  *data = (UInt32*)[drawBitmap bitmapData];
  
  int  x, y;
  int  x0 = (int)(rect.origin.x + 0.5f);
  int  y0 = (int)(rect.origin.y + 0.5f);  
  int  height = (int)(rect.origin.y + rect.size.height + 0.5f) - y0;
  int  width = (int)(rect.origin.x + rect.size.width + 0.5f) - x0;
  int  bitmapWidth = [drawBitmap bytesPerRow] / sizeof(UInt32);
  int  bitmapHeight = [drawBitmap pixelsHigh];
  
  for (y=0; y<height; y++) {
    int  pos = x0 + (bitmapHeight - y0 - y - 1) * bitmapWidth;
    for (x=0; x<width; x++) {
      data[pos] = intColor;
      pos++;
    }
  }
}


- (void) drawGradientFilledRect: (NSRect) rect colorHash: (int) colorHash {
  UInt32  *intColors = 
    &gradientColors[(abs(colorHash) % numGradientColors) * 256];
  UInt32  intColor;
  int  colorIndex;
  
  UInt32  *data = (UInt32*)[drawBitmap bitmapData];
  UInt32  *pos;
  UInt32  *poslim;
  
  int  x, y;
  int  x0 = (int)(rect.origin.x + 0.5f);
  int  y0 = (int)(rect.origin.y + 0.5f);
  int  width = (int)(rect.origin.x + rect.size.width + 0.5f) - x0;
  int  height = (int)(rect.origin.y + rect.size.height + 0.5f) - y0;
  int  bitmapWidth = [drawBitmap bytesPerRow] / sizeof(UInt32);
  int  bitmapHeight = [drawBitmap pixelsHigh];
 
  if (height <= 0 || width <= 0) {
    NSLog(@"Height and width should both be positive: x=%f, y=%f, w=%f, h=%f",
          rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    return;
  }
 
  // Horizontal lines
  for (y=0; y<height; y++) {
    colorIndex = 256 * (y0 + y + 0.5f - rect.origin.y) / rect.size.height;
    // Check for out of bounds, rarely happens but can due to rounding errors.
    if (colorIndex < 0) {
      colorIndex = 0;
    }
    else if (colorIndex > 255) {
      colorIndex = 255;
    }
    intColor = intColors[colorIndex];
    
    x = (height - y - 1) * width / height; // Maximum x. 
    pos = &data[ (bitmapHeight - y0 - y - 1) * bitmapWidth + x0 ];
    poslim = pos + x;
    while (pos < poslim) {
      *pos = intColor;
      pos++;
    }
  }
  
  // Vertical lines
  for (x=0; x<width; x++) {
    colorIndex = 256 * (1 - (x0 + x + 0.5f - rect.origin.x) / rect.size.width);
    // Check for out of bounds, rarely happens but can due to rounding errors.
    if (colorIndex < 0) {
      colorIndex = 0;
    }
    else if (colorIndex > 255) {
      colorIndex = 255;
    }
    intColor = intColors[colorIndex];
    
    y = (width - x - 1) * height / width; // Minimum y.
    pos = &data[ (bitmapHeight - y0 - height) * bitmapWidth + x + x0 ];
    poslim = pos + bitmapWidth * (height - y);
    while (pos < poslim) {
      *pos = intColor;
      pos += bitmapWidth;
    }
  }
}


- (void) initGradientColors {
  NSAssert(colorPalette != nil, @"Color palette must be set.");
  free(gradientColors);

  NSArray  *colorKeys = [colorPalette allKeys];
  numGradientColors = [colorKeys count];
  gradientColors = malloc(sizeof(UInt32) * numGradientColors * 256);
  NSAssert(gradientColors != NULL, @"Failed to malloc gradientColors."); 
  
  NSAutoreleasePool  *localAutoreleasePool = [[NSAutoreleasePool alloc] init];
  
  int  i, j;
  UInt32  *pos = gradientColors;
  
  for (i=0; i<numGradientColors; i++) {    
    NSColor  *color = 
      [colorPalette colorWithKey: [colorKeys objectAtIndex: i]];
    
    // TODO: needed?
    // color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    
    NSColor  *modColor;
    float  hue = [color hueComponent];
    float  saturation = [color saturationComponent];
    float  brightness = [color brightnessComponent];
    float  alpha = [color alphaComponent];

    // Darker colors
    for (j=0; j<128; j++) {
      float  adjust = 0.5f * (float)(128-j) / 128;
      modColor = [NSColor colorWithDeviceHue:hue
                            saturation:saturation
                            brightness:brightness * ( 1 - adjust)
                            alpha:alpha];
                   
      *pos++ = CFSwapInt32BigToHost(
                 ((UInt32)([modColor redComponent] * 255) & 0xFF) << 24 |
                 ((UInt32)([modColor greenComponent] * 255) & 0xFF) << 16 |
                 ((UInt32)([modColor blueComponent] * 255) & 0xFF) << 8);
    }
    
    // Lighter colors
    for (j=0; j<128; j++) {
      float  adjust = 0.5f * (float)j / 128;
      
      // First ramp up brightness, then decrease saturation  
      float dif = 1 - brightness;
      float absAdjust = (dif + saturation) * adjust;

      if (absAdjust < dif) {
        modColor = [NSColor colorWithDeviceHue:hue
                              saturation:saturation
                              brightness:brightness + absAdjust
                              alpha:alpha];
      }
      else {
        modColor = [NSColor colorWithDeviceHue:hue
                              saturation:saturation + dif - absAdjust
                              brightness:1.0f
                              alpha:alpha];
      }
      
      *pos++ = CFSwapInt32BigToHost(
                 ((UInt32)([modColor redComponent] * 255) & 0xFF) << 24 |
                 ((UInt32)([modColor greenComponent] * 255) & 0xFF) << 16 |
                 ((UInt32)([modColor blueComponent] * 255) & 0xFF) << 8);
    }
  }
  
  [localAutoreleasePool release];
}

@end // @implementation ItemTreeDrawer (PrivateMethods)
