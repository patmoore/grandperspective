#import <Cocoa/Cocoa.h>


@class AnnotatedTreeContext;

@interface WriteTaskInput : NSObject {
  AnnotatedTreeContext  *treeContext;
  NSString  *path;
}

- (id) initWithAnnotatedTreeContext: (AnnotatedTreeContext *)context 
         path: (NSString *)path;

- (AnnotatedTreeContext *)annotatedTreeContext;
- (NSString *) path;

@end
