#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class FileItem;


@interface TreeBuilder : NSObject {

  BOOL  abort;
  TreeBalancer  *treeBalancer;

}

- (id) init;

- (void) abort;

- (FileItem*) buildTreeForPath:(NSString*)path;

@end
