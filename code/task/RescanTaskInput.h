#import <Cocoa/Cocoa.h>

#import "ScanTaskInput.h"


@class TreeHistory;


@interface RescanTaskInput : ScanTaskInput {
  TreeHistory  *oldHistory;
}

- (id) initWithOldHistory: (TreeHistory *) oldHistory;

- (TreeHistory *) oldHistory;

@end
