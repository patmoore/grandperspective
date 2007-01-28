#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class DirectoryItem;


#define LOGICAL_FILE_SIZE   0
#define PHYSICAL_FILE_SIZE  1


@interface TreeBuilder : NSObject {

  int  fileSizeMeasure;
  BOOL  abort;
  TreeBalancer  *treeBalancer;

}

- (id) init;

- (void) abort;

- (int) fileSizeMeasure;
- (void) setFileSizeMeasure: (int) measure;

- (DirectoryItem*) buildTreeForPath:(NSString*)path;

@end
