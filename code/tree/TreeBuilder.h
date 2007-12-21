#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class FileItem;
@class DirectoryItem;
@class TreeContext;


extern NSString  *LogicalFileSize;
extern NSString  *PhysicalFileSize;


@interface TreeBuilder : NSObject {

  NSString  *fileSizeMeasure;
  BOOL  useLogicalFileSize;
  
  BOOL  abort;
  TreeBalancer  *treeBalancer;
}

+ (NSArray *) fileSizeMeasureNames;

- (id) init;

- (void) abort;

- (NSString *) fileSizeMeasure;
- (void) setFileSizeMeasure: (NSString *)measure;

- (TreeContext *) buildTreeForPath: (NSString *)path;

@end
