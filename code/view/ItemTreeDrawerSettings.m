#import "ItemTreeDrawerSettings.h"

#import "FileItemHashing.h"


@interface ItemTreeDrawerSettings (PrivateMethods)

+ (NSColorList *) defaultColorPalette;

@end


@implementation ItemTreeDrawerSettings

// Creates default settings.
- (id) init {
  return 
    [self initWithColorMapping: [[[FileItemHashing alloc] init] autorelease]
            colorPalette: [ItemTreeDrawerSettings defaultColorPalette]
            fileItemMask: nil];
}


- (id) initWithColorMapping: (FileItemHashing *)colorMappingVal
         colorPalette: (NSColorList *)colorPaletteVal
         fileItemMask: (NSObject<FileItemTest> *)fileItemMaskVal {
  if (self = [super init]) {
    colorMapping = [colorMappingVal retain];
    colorPalette = [colorPaletteVal retain];
    fileItemMask = [fileItemMaskVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [colorMapping release];
  [colorPalette release];
  [fileItemMask release];
  
  [super dealloc];  
}


- (id) copyWithColorMapping: (FileItemHashing *)colorMappingVal {
  return [[[ItemTreeDrawerSettings alloc]
              initWithColorMapping: colorMappingVal
              colorPalette: colorPalette
              fileItemMask: fileItemMask] autorelease];
}

- (id) copyWithColorPalette: (NSColorList *)colorPaletteVal {
  return [[[ItemTreeDrawerSettings alloc]
              initWithColorMapping: colorMapping
              colorPalette: colorPaletteVal
              fileItemMask: fileItemMask] autorelease];
}

- (id) copyWithFileItemMask: (NSObject<FileItemTest> *)fileItemMaskVal {
  return [[[ItemTreeDrawerSettings alloc]
              initWithColorMapping: colorMapping
              colorPalette: colorPalette
              fileItemMask: fileItemMaskVal] autorelease];
}


- (FileItemHashing*) colorMapping {
  return colorMapping;
}

- (NSColorList*) colorPalette {
  return colorPalette;
}

- (NSObject <FileItemTest> *) fileItemMask {
  return fileItemMask;
}

@end


NSColorList  *defaultColorPalette = nil;

@implementation ItemTreeDrawerSettings (PrivateMethods)

+ (NSColorList *) defaultColorPalette {
  if (defaultColorPalette==nil) {
    NSColorList  *colorList =
      [[NSColorList alloc] initWithName: @"DefaultItemTreeDrawerPalette"];

    [colorList insertColor: [NSColor blueColor]    key: @"blue"    atIndex: 0];
    [colorList insertColor: [NSColor redColor]     key: @"red"     atIndex: 1];
    [colorList insertColor: [NSColor greenColor]   key: @"green"   atIndex: 2];
    [colorList insertColor: [NSColor cyanColor]    key: @"cyan"    atIndex: 3];
    [colorList insertColor: [NSColor magentaColor] key: @"magenta" atIndex: 4];
    [colorList insertColor: [NSColor orangeColor]  key: @"orange"  atIndex: 5];
    [colorList insertColor: [NSColor yellowColor]  key: @"yellow"  atIndex: 6];
    [colorList insertColor: [NSColor purpleColor]  key: @"purple"  atIndex: 7];

    defaultColorPalette = colorList;
  }

  return defaultColorPalette;
}

@end
