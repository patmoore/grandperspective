#import "ReadProgressPanelControl.h"

#import "ReadTaskExecutor.h"


@implementation ReadProgressPanelControl

- (NSString *)windowTitle {
  return NSLocalizedString( @"Loading in progress",
                            @"Title of progress panel." );
}

- (NSString *)progressDetailsFormat {
  return NSLocalizedString( @"Reading %@", 
                            @"Message in progress panel while loading data" );
}

- (NSString *)progressSummaryFormat {
  return NSLocalizedString( @"%d folders read", 
                            @"Message in progress panel while loading data" );
}

- (NSString *)pathFromTaskInput: (id) taskInput {
  return @"???"; // Path is not known until top folder is read from file.
}

- (NSDictionary *)progressInfo {
  return  [((ReadTaskExecutor *)taskExecutor) progressInfo];
}

@end
