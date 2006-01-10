#import <Cocoa/Cocoa.h>


@class FileItem;
@class DirectoryItem;

@interface BalancedTreeBuilder : NSObject {

  BOOL  separateFilesAndDirs;
  BOOL  abort;
  
@private
  NSMutableArray*  tmpArray;
}

- (id)init;

/* Configures whether or not files and directories are entirely 
 * being kept separate in the trees that are build.
 */
- (void) setSeparatesFilesAndDirs:(BOOL)option;
- (BOOL) separatesFilesAndDirs;

- (void) abort;

- (FileItem*) buildTreeForPath:(NSString*)path;

@end
