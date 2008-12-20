#import "ToolbarSegmentedCell.h"


@interface NSSegmentedCell (PrivateMethods)

- (void) setSegmentStyle: (int)style;
- (int) segmentStyle;

- (void) _setSegmentedCellStyle: (int)style;
- (int) _segmentedCellStyle;

@end


@implementation ToolbarSegmentedCell

- (id) initWithSegmentedCell: (NSSegmentedCell *)cell {
  if (self = [super init]) {
    // Copy all settings. 
    //
    // Note: It's a pain to have to explictly copy all settings, but this seems
    // to be the most robust way to get the desired effect. More elegant 
    // approaches do not work, at least not the following ones:
    //
    // - Use a subclass of NSSegmentedControl that overrides -cellClass to
    //   return the class of this cell implementation. Fails because this is
    //   only recently supported by Interface Builder, and requires nib files
    //   of format NIB 3.0 instead of NIB 2.x (which would require OS X 10.5 
    //   as a minimum requirement).
    //
    // - Use a Decorater pattern (with dynamic implementation of the methods 
    //   of the wrapped object). Fails because the -controlSize method is also
    //   used by the object which is decorated, which will still use its own
    //   implementation.
    //
    // Yet another approach would be to construct the NSSegmentedCell 
    // programmatically, and set its cell to this one. That works as well, but
    // has as drawback that the look of the control cannot be changed from the
    // NIB file, using Interface Builder. This could be useful for localizers,
    // e.g. changing the order of the segments to better match the label of
    // the control.
  
    [self setTrackingMode: [cell trackingMode]];
  
    [self setSegmentCount: [cell segmentCount]];
    
    int  i = [self segmentCount];
    while (--i >= 0) {
      [self setWidth:   [cell widthForSegment: i]     forSegment: i];
      [self setImage:   [cell imageForSegment: i]     forSegment: i];
      [self setLabel:   [cell labelForSegment: i]     forSegment: i];
      [self setEnabled: [cell isEnabledForSegment: i] forSegment: i];
      [self setMenu:    [cell menuForSegment: i]      forSegment: i];
      [self setToolTip: [cell toolTipForSegment: i]   forSegment: i];
      [self setTag:     [cell tagForSegment: i]       forSegment: i];
    }
    
    if ( [self respondsToSelector: @selector(setSegmentStyle:)] &&
         [cell respondsToSelector: @selector(segmentStyle)] ) {
      [self setSegmentStyle: [cell segmentStyle]];
    }
    else if ( [self respondsToSelector: @selector(_setSegmentedCellStyle:)] &&
              [cell respondsToSelector: @selector(_segmentedCellStyle)] ) {
      [self _setSegmentedCellStyle: [cell _segmentedCellStyle]];
    }
  }
  
  return self;
}


/* When the toolbar is set to small size, don't change the size of this
 * segmented control.
 */
- (NSControlSize) controlSize {
  return NSRegularControlSize;
}

@end

