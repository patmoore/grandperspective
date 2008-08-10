#import "ScanProgressPanelControl.h"

#import "ScanTaskExecutor.h"
#import "ScanTaskInput.h"
#import "TreeBuilder.h"


@implementation ScanProgressPanelControl

- (NSString *)windowTitle {
  return NSLocalizedString( @"Scanning in progress",
                            @"Title of progress panel." );
}

- (NSString *)progressDetailsFormat {
  return NSLocalizedString( @"Scanning %@", 
                            @"Message in progress panel while scanning" );
}

- (NSString *)progressSummaryFormat {
  return NSLocalizedString( @"%d folders scanned", 
                            @"Message in progress panel while scanning" );
}

- (NSString *)pathFromTaskInput: (id) taskInput {
  return [taskInput pathToScan];
}

- (NSDictionary *)progressInfo {
  return  [((ScanTaskExecutor *)taskExecutor) scanProgressInfo];
}

@end // @implementation ScanProgressPanelControl
