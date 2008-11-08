#import "GradientRectangleDrawer.h"


@interface GradientRectangleDrawer (PrivateMethods)

- (void) initGradientColors;

@end


@implementation GradientRectangleDrawer

- (id) init {
  NSAssert(NO, @"Use -initWithColorPalette: instead.");
}

- (id) initWithColorPalette: (NSColorList *)colorPaletteVal {
  if (self = [super init]) {
    [self setColorPalette: colorPaletteVal];
    [self setColorGradient: 0.5f];
  }
  
  return self;
}

- (void) dealloc {
  [colorPalette release];

  free(gradientColors);
  
  NSAssert(drawBitmap==nil, @"Bitmap should be nil.");

  [super dealloc];
}


- (NSImage *) drawImageOfGradientRectangleWithColor: (int) colorIndex
                inRect: (NSRect) bounds {
  [self setupBitmap: bounds];
  
  [self drawGradientFilledRect: bounds colorIndex: colorIndex];
  
  return [self createImageFromBitmap];
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


- (void) setColorGradient: (float) gradient {
  NSAssert(gradient >= 0 && gradient <= 1, @"Invalid gradient value.");
  
  if (gradient != colorGradient) {
    colorGradient = gradient;

    initGradientColors = YES;
  }
}

- (float) colorGradient {
  return colorGradient;
}

@end // @implementation GradientRectangleDrawer


@implementation GradientRectangleDrawer (ProtectedMethods) 

- (void) setupBitmap: (NSRect) bounds {
  NSAssert(drawBitmap == nil, @"Bitmap should be nil.");

  bitmapBounds = bounds;

  drawBitmap =  
    [[NSBitmapImageRep alloc] 
      initWithBitmapDataPlanes: NULL
      pixelsWide: (int) bitmapBounds.size.width
      pixelsHigh: (int) bitmapBounds.size.height
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
}


- (NSImage *) createImageFromBitmap {
  NSImage  *image = 
    [[[NSImage alloc] initWithSize: bitmapBounds.size] autorelease];
  [image addRepresentation: drawBitmap];

  [drawBitmap release];
  drawBitmap = nil;

  return image;
}


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


- (void) drawGradientFilledRect: (NSRect) rect colorIndex: (int) colorIndex {
  UInt32  *intColors = &gradientColors[colorIndex * 256];
  UInt32  intColor;
  int  gradient;
  
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
    gradient = 256 * (y0 + y + 0.5f - rect.origin.y) / rect.size.height;
    // Check for out of bounds, rarely happens but can due to rounding errors.
    intColor = intColors[ MIN(255, MAX(0, gradient)) ];
    
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
    gradient = 256 * (1 - (x0 + x + 0.5f - rect.origin.x) / rect.size.width);
    // Check for out of bounds, rarely happens but can due to rounding errors.
    intColor = intColors[ MIN(255, MAX(0, gradient)) ];
    
    y = (width - x - 1) * height / width; // Minimum y.
    pos = &data[ (bitmapHeight - y0 - height) * bitmapWidth + x + x0 ];
    poslim = pos + bitmapWidth * (height - y);
    while (pos < poslim) {
      *pos = intColor;
      pos += bitmapWidth;
    }
  }
}

@end // @implementation GradientRectangleDrawer (ProtectedMethods)


@implementation GradientRectangleDrawer (PrivateMethods)

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
      float  adjust = colorGradient * (float)(128-j) / 128;
      modColor = [NSColor colorWithDeviceHue: hue
                            saturation: saturation
                            brightness: brightness * ( 1 - adjust)
                            alpha: alpha];
                   
      *pos++ = CFSwapInt32BigToHost(
                 ((UInt32)([modColor redComponent] * 255) & 0xFF) << 24 |
                 ((UInt32)([modColor greenComponent] * 255) & 0xFF) << 16 |
                 ((UInt32)([modColor blueComponent] * 255) & 0xFF) << 8);
    }
    
    // Lighter colors
    for (j=0; j<128; j++) {
      float  adjust = colorGradient * (float)j / 128;
      
      // First ramp up brightness, then decrease saturation  
      float dif = 1 - brightness;
      float absAdjust = (dif + saturation) * adjust;

      if (absAdjust < dif) {
        modColor = [NSColor colorWithDeviceHue: hue
                              saturation: saturation
                              brightness: brightness + absAdjust
                              alpha: alpha];
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

@end // @implementation GradientRectangleDrawer (PrivateMethods)

