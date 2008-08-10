#import <Cocoa/Cocoa.h>


@class TreeContext;

@interface WriteTaskInput : NSObject {
  TreeContext  *treeContext;
  NSString  *path;
}

- (id) initWithTreeContext: (TreeContext *)treeContext path: (NSString *)path;

- (TreeContext *)treeContext;
- (NSString *) path;

@end
