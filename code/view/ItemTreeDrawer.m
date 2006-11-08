#import "ItemTreeDrawer.h"

#import "FileItem.h"
#import "FileItemHashing.h"
#import "TreeLayoutBuilder.h"

#import "FileItemTest.h"

@interface ItemTreeDrawer (PrivateMethods)

- (NSColorList*) defaultColorPalette;
- (void) drawBasicFilledRect:(NSRect)rect colorHash:(int)hash;
- (void) drawGradientFilledRect:(NSRect)rect colorHash:(int)hash;
- (void) calculateGradientColors;

@end


@implementation ItemTreeDrawer

- (id) init {
  return [self initWithFileItemHashing:
           [[[FileItemHashing alloc] init] autorelease]];
}

- (id) initWithFileItemHashing: (FileItemHashing*)fileItemHashingVal {
  return [self initWithFileItemHashing: fileItemHashingVal
                 colorPalette: [self defaultColorPalette]
                 layoutBuilder: [[[TreeLayoutBuilder alloc] init] autorelease]];
}

- (id) initWithFileItemHashing: (FileItemHashing*)fileItemHashingVal
         colorPalette: (NSColorList*)colorPaletteVal
         layoutBuilder: (TreeLayoutBuilder*)layoutBuilderVal {
  if (self = [super init]) {
    fileItemHashing = [fileItemHashingVal retain];
    
    // Also calculates gradient color array.
    [self setColorPalette: colorPaletteVal];
    
    layoutBuilder = [layoutBuilderVal retain];
    
    abort = NO;
  }
  return self;
}

- (void) dealloc {
  [layoutBuilder release];
  [fileItemHashing release];
  [colorPalette release];
  [fileItemMask release];
  
  free(gradientColors);
  
  NSAssert(drawBitmap==nil, @"Bitmap should be nil.");
  
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


- (void) setFileItemMask:(NSObject <FileItemTest>*)fileItemMaskVal {
  if (fileItemMaskVal != fileItemMask) {
    [fileItemMask release];
    fileItemMask = [fileItemMaskVal retain];
  }
}

- (NSObject <FileItemTest> *) fileItemMask {
  return fileItemMask;
}


- (void) setColorPalette: (NSColorList*)colorPaletteVal {
  if (colorPaletteVal != colorPalette) {
    [colorPalette release];
    colorPalette = [colorPaletteVal retain];

    [self calculateGradientColors];
  }
}


- (NSColorList*) colorPalette {
  return colorPalette;
}


- (NSImage*) drawImageOfItemTree: (Item*)itemTreeRoot inRect: (NSRect)bounds {
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
  
  // TODO: cope with fact when bounds not start at (0, 0)? Would this every be
  // useful/occur?
  [layoutBuilder layoutItemTree:itemTreeRoot inRect:bounds traverser:self];

  NSImage  *image = nil;

  if (!abort) {
    NSLog(@"Done drawing. Time taken=%f", -[startTime timeIntervalSinceNow]);

    image = [[[NSImage alloc] initWithSize:bounds.size] autorelease];
    [image addRepresentation:drawBitmap];
  }
  abort = NO; // Enable drawer again for next time.

  [drawBitmap release];
  drawBitmap = nil;

  return image;
}


- (void) abortDrawing {
  abort = YES;
}


- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  if (![item isVirtual]) {
    FileItem*  file = (FileItem*)item;
    
    if ( [file isPlainFile] && ( fileItemMask==nil 
                                 || [fileItemMask testFileItem:file] ) ) {
      [self drawGradientFilledRect:rect 
              colorHash:[fileItemHashing hashForFileItem:file depth:depth]];
    }
  }

  // Only descend/continue when the current drawing task has not been aborted.
  return !abort;
}

@end // @implementation ItemTreeDrawer


@implementation ItemTreeDrawer (PrivateMethods)

- (NSColorList*) defaultColorPalette {
  NSColorList  *colorList = [[NSColorList alloc] 
                                initWithName: @"DefaultItemTreeDrawerPalette"];
  [colorList insertColor: [NSColor blueColor]    key: @"blue"    atIndex: 0];
  [colorList insertColor: [NSColor redColor]     key: @"red"     atIndex: 1];
  [colorList insertColor: [NSColor greenColor]   key: @"green"   atIndex: 2];
  [colorList insertColor: [NSColor cyanColor]    key: @"cyan"    atIndex: 3];
  [colorList insertColor: [NSColor magentaColor] key: @"magenta" atIndex: 4];
  [colorList insertColor: [NSColor orangeColor]  key: @"orange"  atIndex: 5];
  [colorList insertColor: [NSColor yellowColor]  key: @"yellow"  atIndex: 6];
  [colorList insertColor: [NSColor purpleColor]  key: @"purple"  atIndex: 7];

  return [colorList autorelease];
}

- (void)drawBasicFilledRect:(NSRect)rect colorHash:(int)colorHash {
  UInt32  intColor = 
    gradientColors[(abs(colorHash) % numGradientColors) * 256 + 128];

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


- (void)drawGradientFilledRect:(NSRect)rect colorHash:(int)colorHash {
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


- (void) calculateGradientColors {
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
    NSColor  *color = [colorPalette colorWithKey: [colorKeys objectAtIndex: i]];
    
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
