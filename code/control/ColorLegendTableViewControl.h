#import <Cocoa/Cocoa.h>


@class DirectoryView;

@interface ColorLegendTableViewControl : NSObject {

  DirectoryView  *dirView;
  NSTableView  *tableView;
  NSMutableArray  *colorImages;

}

- (id) initWithDirectoryView: (DirectoryView *)dirView 
         tableView: (NSTableView *)tableView;

@end
