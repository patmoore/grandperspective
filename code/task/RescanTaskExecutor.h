#import <Cocoa/Cocoa.h>

#import "ScanTaskExecutor.h"

@class TreeFilter;


@interface RescanTaskExecutor : ScanTaskExecutor {
  TreeFilter  *treeFilter;
}

@end
