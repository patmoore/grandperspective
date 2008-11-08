#import <Cocoa/Cocoa.h>


@interface GradientRectangleDrawer : NSObject {

  NSColorList  *colorPalette;
  float  colorGradient;
  
  BOOL  initGradientColors;
  UInt32  *gradientColors;
  int  numGradientColors;

  NSRect  bitmapBounds;
  NSBitmapImageRep  *drawBitmap;

}

- (id) initWithColorPalette: (NSColorList *)colorPalette;

- (void) setColorPalette: (NSColorList *)colorPalette;
- (NSColorList *) colorPalette;

/* Sets the color gradient, which determines how much the color of each
 * rectangle varies. The value should be between 0 (uniform color) and 1 
 * (maximum color difference).
 */
- (void) setColorGradient: (float) gradient;
- (float) colorGradient;

- (NSImage *) drawImageOfGradientRectangleWithColor: (int) colorIndex
                inRect: (NSRect) bounds;
                
@end


@interface GradientRectangleDrawer (ProtectedMethods) 

/* Sets up a bitmap, to be used for drawing
 */
- (void) setupBitmap: (NSRect) bounds;

/* Creates an image from the bitmap, and disposes of the bitmap.
 */
- (NSImage *) createImageFromBitmap;

- (UInt32) intValueForColor: (NSColor *)color;

- (void) drawBasicFilledRect: (NSRect) rect intColor: (UInt32) intColor;

- (void) drawGradientFilledRect: (NSRect) rect colorIndex: (int) colorIndex;

@end
