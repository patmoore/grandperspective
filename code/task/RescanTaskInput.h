#import <Cocoa/Cocoa.h>

#import "ScanTaskInput.h"


@class TreeContext;


@interface RescanTaskInput : ScanTaskInput {
  TreeContext  *oldContext;
}

- (id) initWithOldContext: (TreeContext *) oldContext;

- (TreeContext *) oldContext;

@end
