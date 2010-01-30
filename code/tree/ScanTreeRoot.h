#import <Cocoa/Cocoa.h>

#import "DirectoryItem.h"

/* The directory item that is at the root of the scan tree.
 */
@interface ScanTreeRoot : DirectoryItem {
  NSString  *systemName;
}

@end // @interface ScanTreeRoot
