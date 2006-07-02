#import <Cocoa/Cocoa.h>


@class FileItem;


@interface TreeBuilder : NSObject {

  BOOL  abort;

}

- (id)init;

- (void) abort;

- (FileItem*) buildTreeForPath:(NSString*)path;

@end
