#import "WriteProgressPanelControl.h"

#import "WriteTaskExecutor.h"
#import "WriteTaskInput.h"
#import "TreeContext.h"
#import "AnnotatedTreeContext.h"


@implementation WriteProgressPanelControl

- (NSString *)windowTitle {
  return NSLocalizedString( @"Saving in progress",
                            @"Title of progress panel." );
}

- (NSString *)progressDetailsFormat {
  return NSLocalizedString( @"Saving %@", 
                            @"Message in progress panel while saving data" );
}

- (NSString *)progressSummaryFormat {
  return NSLocalizedString( @"%d folders saved", 
                            @"Message in progress panel while saving data" );
}

- (NSString *)pathFromTaskInput: (id) taskInput {
  return [[[[taskInput annotatedTreeContext] treeContext] scanTree] path];
}

- (NSDictionary *)progressInfo {
  return  [((WriteTaskExecutor *)taskExecutor) progressInfo];
}

@end
