#import "FilterProgressPanelControl.h"

#import "FilterTaskInput.h"
#import "TreeContext.h"


@implementation FilterProgressPanelControl

- (void) windowDidLoad {
  [super windowDidLoad];
  
  [[self window] setTitle: NSLocalizedString( @"Filtering in progress",
                                              @"Title of progress panel." )];
}

- (void) initProgressInfoForTaskWithInput: (id) taskInput {
  NSString  *format = NSLocalizedString( 
                        @"Filtering %@", 
                        @"Message in progress panel while filtering" );
  NSString  *path = [[[taskInput oldContext] scanTree] path];

  [progressDetails setStringValue: [NSString stringWithFormat: format, path]];
}

@end
