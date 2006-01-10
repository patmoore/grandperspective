#import "ColorPalette.h"


@implementation ColorPalette

ColorPalette  *defaultPalette = nil;

+ (ColorPalette*) defaultColorPalette {
  if (defaultPalette == nil) {
    defaultPalette = [[ColorPalette alloc] init];
  }
  
  return defaultPalette;
}

// Uses a default list of eight colors.
// Overrides super's designated initialiser.
- (id) init {
  NSMutableArray  *colors = [NSMutableArray arrayWithCapacity:8];

  [colors addObject:[NSColor blueColor]];
  [colors addObject:[NSColor redColor]];
  [colors addObject:[NSColor greenColor]];
  [colors addObject:[NSColor cyanColor]];
  [colors addObject:[NSColor magentaColor]];
  [colors addObject:[NSColor orangeColor]];
  [colors addObject:[NSColor yellowColor]];
  [colors addObject:[NSColor purpleColor]];
  
  return [self initWithColors:colors];
}

- (id) initWithColors:(NSArray*)colorArrayVal {
  if (self = [super init]) {
    colorArray = [colorArrayVal retain];
  }
  return self;
}

- (void) dealloc {
  [colorArray release];
  
  [super dealloc];
}

- (NSColor*) getColorForInt:(unsigned)intVal {
  return [colorArray objectAtIndex:(intVal % [colorArray count])];
  // Note: not retaining-autoreleasing it for efficiency. Should be okay as
  // the color palette should be longer lived than the stack whenever this
  // method is called
}

- (int) numColors {
  return [colorArray count];
}

@end
