#import "ItemTreeDrawer.h"

#import "FileItem.h"
#import "FileItemHashing.h"
#import "ColorPalette.h"
#import "TreeLayoutBuilder.h"


@interface ItemTreeDrawer (PrivateMethods)

// Implicitly implement "TreeLayoutTraverser" protocol.
- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth;

- (void) drawBasicFilledRect:(NSRect)rect colorHash:(int)hash;
- (void) drawGradientFilledRect:(NSRect)rect colorHash:(int)hash;
- (void) calculateGradientColors;

@end


@implementation ItemTreeDrawer

- (id) init {
  return [self initWithFileItemHashing:
           [[[FileItemHashing alloc] init] autorelease]];
}

- (id) initWithFileItemHashing:(FileItemHashing*)fileItemHashingVal {
  return [self initWithFileItemHashing: fileItemHashingVal
                 colorPalette: [ColorPalette defaultColorPalette]
                 layoutBuilder: [[[TreeLayoutBuilder alloc] init] autorelease]];
}

- (id) initWithFileItemHashing: (FileItemHashing*)fileItemHashingVal
         colorPalette: (ColorPalette*)colorPaletteVal
         layoutBuilder: (TreeLayoutBuilder*)layoutBuilderVal {
  if (self = [super init]) {
    fileItemHashing = [fileItemHashingVal retain];
    
    colorPalette = [colorPaletteVal retain];
    
    layoutBuilder = [layoutBuilderVal retain];
    
    abort = NO;
  }
  return self;
}

- (void) dealloc {
  [layoutBuilder release];
  [fileItemHashing release];
  [colorPalette release];
  
  [gradientColors release];
  
  [super dealloc];
}


- (void) setTreeLayoutBuilder: (TreeLayoutBuilder*)layoutBuilderVal {
  if (layoutBuilderVal != layoutBuilder) {
    [layoutBuilder release];
    layoutBuilder = [layoutBuilderVal retain];
  }
}

- (TreeLayoutBuilder*) treeLayoutBuilder {
  return layoutBuilder;
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


- (void) setColorPalette:(ColorPalette*)colorPaletteVal {
  if (colorPaletteVal != colorPalette) {
    [colorPalette release];
    colorPalette = colorPaletteVal;
  }
}


- (NSImage*) drawImageOfItemTree: (Item*)itemTreeRoot inRect: (NSRect)bounds {
  NSDate  *startTime = [NSDate date];
  
  if (colorPalette!=nil) {
    [self calculateGradientColors];
    [colorPalette release];
    colorPalette = nil;
  }

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
  
  // TODO: cope with fact when bounds not start at (0, 0)? Would this every be
  // useful/occur?
  id  traverser = self;
  [layoutBuilder layoutItemTree: itemTreeRoot inRect: bounds 
                 traverser: traverser];

  NSImage  *image = nil;

  if (!abort) {
    NSLog(@"Done drawing. Time taken=%f", -[startTime timeIntervalSinceNow]);

    image = [[NSImage alloc] initWithSize:bounds.size];
    [image addRepresentation:drawBitmap];
  }

  [drawBitmap release];
  drawBitmap = nil;

  return image;
}


- (void) abortDrawing {
  abort = YES;
}

- (void) resetAbortDrawingFlag {
  abort = NO;
}


@end // @implementation ItemTreeDrawer


@implementation ItemTreeDrawer (PrivateMethods)

- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  if (![item isVirtual]) {
    id  file = item;

    if ([file isPlainFile]) {
      [self drawGradientFilledRect:rect 
              colorHash:[fileItemHashing hashForFileItem:file depth:depth]];
    }
  }

  // Only descend/continue when the current drawing task has not been aborted.
  return !abort;
}


- (void)drawBasicFilledRect:(NSRect)rect colorHash:(int)colorHash {
  NSColor  * intColor = 
    [gradientColors objectAtIndex:((abs(colorHash) % numGradientColors) * 256 + 128)];
  
  int  x, y;
  int  x0 = (int)(rect.origin.x + 0.5f);
  int  y0 = (int)(rect.origin.y + 0.5f);  
  int  height = (int)(rect.origin.y + rect.size.height + 0.5f) - y0;
  int  width = (int)(rect.origin.x + rect.size.width + 0.5f) - x0;
  int  bitmapHeight = [drawBitmap pixelsHigh];
  
  for (y=y0; y<y0+height; y++) {
    for (x=x0; x<x0+width; x++) {
        [drawBitmap setColor:intColor atX:x y:bitmapHeight-y];
    }
  }
}


- (void)drawGradientFilledRect:(NSRect)rect colorHash:(int)colorHash {
  UInt32 baseColorIndex = (abs(colorHash) % numGradientColors) * 256;
  int  colorIndex;
  NSColor * intColor;
  
  int  x, y;
  int  x0 = (int)(rect.origin.x + 0.5f);
  int  y0 = (int)(rect.origin.y + 0.5f);
  int  width = (int)(rect.origin.x + rect.size.width + 0.5f) - x0;
  int  height = (int)(rect.origin.y + rect.size.height + 0.5f) - y0;
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
    intColor = [gradientColors objectAtIndex:(baseColorIndex + colorIndex)];
    
    for(x=0; x < ((height - y - 1) * width / height); x++)
    {
        [drawBitmap setColor:intColor atX:(x0+x) y:bitmapHeight-(y0+y)];
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
    intColor = [gradientColors objectAtIndex:(baseColorIndex + colorIndex)];
    
    for(y=(width - x - 1) * height / width; y < height; y++)
    {
        [drawBitmap setColor:intColor atX:(x0+x) y:bitmapHeight-(y0+y)];
    }
  }
}


- (void) calculateGradientColors {
  NSAssert(colorPalette != nil, @"Color palette must be set.");

//  NSAutoreleasePool  *localAutoreleasePool = [[NSAutoreleasePool alloc] init];
  
  numGradientColors = [colorPalette numColors];
  [gradientColors release];
  gradientColors = [NSMutableArray arrayWithCapacity:(numGradientColors * 256)];
  NSAssert(gradientColors != NULL, @"Failed to create gradientColors.");
  
  int  i, j;
  
  for (i=0; i<[colorPalette numColors]; i++) {    
    NSColor  *color = [colorPalette getColorForInt:i];
    
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
                   
      [gradientColors addObject:modColor];
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
      
      [gradientColors addObject:modColor];
    }
  }
  
//  [localAutoreleasePool release];
}

@end // @implementation ItemTreeDrawer (PrivateMethods)
