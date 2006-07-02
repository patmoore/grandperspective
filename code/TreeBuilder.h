#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class DirectoryItem;


@interface TreeBuilder : NSObject {

  BOOL  abort;
  TreeBalancer  *treeBalancer;

}

- (id) init;

- (void) abort;

- (DirectoryItem*) buildTreeForPath:(NSString*)path;

@end
