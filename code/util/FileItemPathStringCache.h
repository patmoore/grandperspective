#import <Cocoa/Cocoa.h>


@class FileItem;

@interface FileItemPathStringCache : NSObject {

  BOOL  addTrailingSlashToDirectoryPaths;
  NSMutableArray  *cachedPathStrings;
  FileItem  *lastFileItem;

}

- (BOOL) addTrailingSlashToDirectoryPaths;
- (void) setAddTrailingSlashToDirectoryPaths: (BOOL)flag;

- (NSString*) pathStringForFileItem: (FileItem *)item;
- (void) clearCache;

@end
