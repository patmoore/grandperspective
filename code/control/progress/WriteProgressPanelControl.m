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
  return NSLocalizedString( @"Writing %@", 
                            @"Message in progress panel while saving data" );
}

- (NSString *)progressSummaryFormat {
  return NSLocalizedString( @"%d folders written", 
                            @"Message in progress panel while saving data" );
}

- (NSString *)pathFromTaskInput: (id) taskInput {
  return [[[taskInput treeContext] scanTree] path];
}

- (NSDictionary *)progressInfo {
  return  [((WriteTaskExecutor *)taskExecutor) progressInfo];
}

@end
