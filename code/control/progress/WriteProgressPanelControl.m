#import "WriteProgressPanelControl.h"

#import "WriteTaskExecutor.h"
#import "WriteTaskInput.h"
#import "TreeContext.h"


@implementation WriteProgressPanelControl

- (NSString *)windowTitle {
  return NSLocalizedString( @"Saving in progress",
                            @"Title of progress panel." );
}

- (NSString *)progressDetailsFormat {
  return NSLocalizedString( @"Saving %@", 
                            @"Message in progress panel while writing data" );
}

- (NSString *)progressSummaryFormat {
  return NSLocalizedString( @"%d folders written", 
                            @"Message in progress panel while writing data" );
}

- (NSString *)pathFromTaskInput: (id) taskInput {
  return [[[taskInput treeContext] scanTree] path];
}

- (NSDictionary *)progressInfo {
  return  [((WriteTaskExecutor *)taskExecutor) writeProgressInfo];
}

@end
