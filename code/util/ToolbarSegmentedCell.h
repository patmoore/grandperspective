#import <Cocoa/Cocoa.h>


/* Extends NSSegmentedCell for use in a toolbar. More specifically, it ensures
 * that the control remains at its normal size, even when the toolbar is set
 * to use small size. The small size is pretty ugly, and the normal size 
 * height is small enough to be used as a small control.
 */
@interface ToolbarSegmentedCell : NSSegmentedCell {
}

/* Initialises the cell using the settings of the provided cell.
 */
- (id) initWithSegmentedCell: (NSSegmentedCell *)cell;

@end
