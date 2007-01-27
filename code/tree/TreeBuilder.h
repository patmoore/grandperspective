#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class DirectoryItem;


#define LOGICAL_FILE_SIZE   0
#define PHYSICAL_FILE_SIZE  1


@interface TreeBuilder : NSObject {

  BOOL  fileSizeType;
  BOOL  abort;
  TreeBalancer  *treeBalancer;

}

- (id) init;

- (void) abort;

- (int) fileSizeType;
- (void) setFileSizeType: (int)type;

- (DirectoryItem*) buildTreeForPath:(NSString*)path;

@end
