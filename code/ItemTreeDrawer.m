#import "ItemTreeDrawer.h"

#import "FileItem.h"
#import "FileItemHashing.h"
#import "ColorPalette.h"
#import "TreeLayoutBuilder.h"

enum {
  IMAGE_TASK_PENDING = 345,
  NO_IMAGE_TASK
};

@interface ItemTreeDrawer (PrivateMethods)

- (void) defaultPostNotificationName:(NSString*)notificationName;
- (void) imageDrawLoop;
- (void) backgroundDrawItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder 
           inRect:(NSRect)bounds;
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
  return [self initWithFileItemHashing:fileItemHashingVal
                 colorPalette:[ColorPalette defaultColorPalette]];
}

- (id) initWithFileItemHashing:(FileItemHashing*)fileItemHashingVal
         colorPalette:(ColorPalette*)colorPaletteVal {
  if (self = [super init]) {
    fileItemHashing = fileItemHashingVal;
    [fileItemHashing retain];
    
    colorPalette = colorPaletteVal;
    [colorPalette retain];
  
    workLock = [[NSConditionLock alloc] initWithCondition:NO_IMAGE_TASK];
    settingsLock = [[NSLock alloc] init];
    abort = NO;

    [NSThread detachNewThreadSelector:@selector(imageDrawLoop)
                toTarget:self withObject:nil];
  }
  return self;
}

- (void) dealloc {
  [fileItemHashing release];
  [colorPalette release];
  
  free(gradientColors);
  
  [image release];
  
  [workLock release];
  [settingsLock release];
  
  [drawItemTree release];
  [drawLayoutBuilder release];
  
  [super dealloc];
}

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashingVal {
  if (fileItemHashingVal != fileItemHashing) {
    [fileItemHashing release];
    fileItemHashing = [fileItemHashingVal retain];
    
    [self resetImage];
  }
}

- (FileItemHashing*) fileItemHashing {
  return fileItemHashing;
}


- (void) setColorPalette:(ColorPalette*)colorPaletteVal {
  [settingsLock lock];
  [colorPaletteVal retain];
  [colorPalette release];
  colorPalette = colorPaletteVal;
  [settingsLock unlock];

  [self resetImage];
}



- (NSImage*) getImage {
  [settingsLock lock];
  NSImage*  returnImage = [[image retain] autorelease];
  [settingsLock unlock];
  
  return returnImage;
}

- (void) resetImage {
  [settingsLock lock];
  [image release];
  image = nil;
  [settingsLock unlock];
}


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

- (void) drawItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           inRect:(NSRect)bounds {
  [settingsLock lock];
  if (drawItemTree != itemTreeRoot) {
    [drawItemTree release];
    drawItemTree = [itemTreeRoot retain];
  }
  if (drawLayoutBuilder != layoutBuilder) {
    [drawLayoutBuilder release];
    drawLayoutBuilder = [layoutBuilder retain];
  }
  drawInRect = bounds;
  abort = YES;

  if ([workLock condition] == NO_IMAGE_TASK) {
    // Notify waiting thread
    [workLock lock];
    [workLock unlockWithCondition:IMAGE_TASK_PENDING];
  }
  [settingsLock unlock];
}

@end // @implementation ItemTreeDrawer


@implementation ItemTreeDrawer (PrivateMethods)

- (void) defaultPostNotificationName:(NSString*)notificationName {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:notificationName object:self];
}

- (void) imageDrawLoop {
  while (YES) {
    NSAutoreleasePool  *pool = [[NSAutoreleasePool alloc] init];

    [workLock lockWhenCondition:IMAGE_TASK_PENDING];
        
    [settingsLock lock];
    NSAssert(drawItemTree != nil && drawLayoutBuilder != nil, 
             @"Draw task not set properly.");
    Item  *tree = [drawItemTree autorelease];
    TreeLayoutBuilder  *builder = [drawLayoutBuilder autorelease];
    NSRect  rect = drawInRect;
    drawItemTree = nil;
    drawLayoutBuilder = nil;
    abort = NO;
    
    NSDate  *startTime = [NSDate date];
    
    if (colorPalette!=nil) {
      [self calculateGradientColors];
      [colorPalette release];
      colorPalette = nil;
    }
    
    [settingsLock unlock];

    [self backgroundDrawItemTree:tree usingLayoutBuilder:builder inRect:rect];
    
    [settingsLock lock];
    if (!abort) {
      [self performSelectorOnMainThread:@selector(defaultPostNotificationName:)
              withObject:@"itemTreeImageReady" waitUntilDone:NO];
      
      [workLock unlockWithCondition:NO_IMAGE_TASK];
      
      //NSLog(@"Done drawing. Time taken=%f", -[startTime timeIntervalSinceNow]);
    }
    else {
      [workLock unlockWithCondition:IMAGE_TASK_PENDING];
    }
    [settingsLock unlock];
    
    [pool release];
  }
}

// Called from own thread.
- (void) backgroundDrawItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           inRect:(NSRect)bounds {
  [self resetImage];
  
  drawBitmap = [[NSBitmapImageRep alloc] 
                 initWithBitmapDataPlanes:NULL
                 pixelsWide:(int)bounds.size.width
                 pixelsHigh:(int)bounds.size.height
                 bitsPerSample:8
                 samplesPerPixel:3
                 hasAlpha:NO
                 isPlanar:NO
                 colorSpaceName:NSDeviceRGBColorSpace
                 bytesPerRow:0
                 bitsPerPixel:32];
  
  // TODO: cope with fact when bounds not start at (0, 0)? Would this every be
  // useful/occur?
  [layoutBuilder layoutItemTree:itemTreeRoot inRect:bounds traverser:self];

  [settingsLock lock];
  if (!abort) {
    image = [[NSImage alloc] initWithSize:bounds.size];
    [image addRepresentation:drawBitmap];
  }
  [settingsLock unlock];

  [drawBitmap release];
  drawBitmap = nil;
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
  int  bitmapWidth = [drawBitmap pixelsWide];
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
  int  bitmapWidth = [drawBitmap pixelsWide];
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

  numGradientColors = [colorPalette numColors];
  gradientColors = malloc(sizeof(UInt32) * numGradientColors * 256);
  NSAssert(gradientColors != NULL, @"Failed to malloc gradientColors."); 
  
  NSAutoreleasePool  *localAutoreleasePool = [[NSAutoreleasePool alloc] init];
  
  int  i, j;
  UInt32  *pos = gradientColors;
  
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
                   
      *pos++ = ((UInt32)([modColor redComponent] * 255) & 0xFF) << 24 |
               ((UInt32)([modColor greenComponent] * 255) & 0xFF) << 16 |
               ((UInt32)([modColor blueComponent] * 255) & 0xFF) << 8;
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
      
      *pos++ = ((UInt32)([modColor redComponent] * 255) & 0xFF) << 24 |
               ((UInt32)([modColor greenComponent] * 255) & 0xFF) << 16 |
               ((UInt32)([modColor blueComponent] * 255) & 0xFF) << 8;
    }
  }
  
  [localAutoreleasePool release];
}

@end // @implementation ItemTreeDrawer (PrivateMethods)
