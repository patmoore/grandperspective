#import <Cocoa/Cocoa.h>


extern NSString  *ToolbarNavigateUp;
extern NSString  *ToolbarNavigateDown; 
extern NSString  *ToolbarOpenItem;
extern NSString  *ToolbarDeleteItem;
extern NSString  *ToolbarToggleInfoDrawer;


@class DirectoryViewControl;

@interface DirectoryViewToolbarControl : NSObject {

  DirectoryViewControl  *dirView;

}

- (id) initWithDirectoryView: (DirectoryViewControl *)dirView;

@end
