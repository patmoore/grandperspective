#import "ScanProgressPanelControl.h"

#import "ScanTaskExecutor.h"
#import "ScanTaskInput.h"
#import "TreeBuilder.h"


@interface ScanProgressPanelControl (PrivateMethods)

- (void) updateProgressDetails: (NSString *)currentPath;
- (void) updateProgressSummary: (int) numFoldersScanned;

@end


@implementation ScanProgressPanelControl

- (void) windowDidLoad {
  [super windowDidLoad];
  
  [[self window] setTitle: NSLocalizedString( @"Scanning in progress",
                                              @"Title of progress panel." )];
}

- (void) initProgressInfoForTaskWithInput: (id) taskInput {
  [self updateProgressDetails: [taskInput directoryName]];
  [self updateProgressSummary: 0];
}

- (void) updateProgressInfo {
  NSDictionary  *dict = [((ScanTaskExecutor *)taskExecutor) scanProgressInfo];
  if (dict == nil) {
    return;
  }
  
  [self updateProgressDetails: [dict objectForKey: CurrentFolderPathKey]];
  [self updateProgressSummary: 
          [[dict objectForKey: NumFoldersBuiltKey] intValue]];  
}

@end // @implementation ScanProgressPanelControl


@implementation ScanProgressPanelControl (PrivateMethods)

- (void) updateProgressDetails: (NSString *)currentPath {
  NSString  *format = 
    NSLocalizedString( @"Scanning %@", 
                       @"Message in progress panel while scanning" );
  [progressDetails setStringValue: 
                     [NSString stringWithFormat: format, currentPath]];
}

- (void) updateProgressSummary: (int) numFoldersScanned {
  NSString  *format = 
    NSLocalizedString( @"%d folders scanned", 
                       @"Message in progress panel while scanning" );
  [progressSummary setStringValue: 
                     [NSString stringWithFormat: format, numFoldersScanned]];
}

@end // @implementation ScanProgressPanelControl (PrivateMethods)

