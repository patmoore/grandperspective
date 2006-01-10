#import <Cocoa/Cocoa.h>


@interface ColorPalette : NSObject {

  NSArray  *colorArray;

}

+ (ColorPalette*) defaultColorPalette;

- (id) initWithColors:(NSArray*)colorArray;

- (NSColor*) getColorForInt:(unsigned)intVal;

- (int) numColors;

@end
