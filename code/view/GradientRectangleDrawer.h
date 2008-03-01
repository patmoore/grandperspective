#import <Cocoa/Cocoa.h>


@interface GradientRectangleDrawer : NSObject {

  NSColorList  *colorPalette;
  
  BOOL  initGradientColors;
  UInt32  *gradientColors;
  int  numGradientColors;

  NSRect  bitmapBounds;
  NSBitmapImageRep  *drawBitmap;

}

- (id) initWithColorPalette: (NSColorList *)colorPalette;

- (void) setColorPalette: (NSColorList *)colorPalette;
- (NSColorList *) colorPalette;

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
