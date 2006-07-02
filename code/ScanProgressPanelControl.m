#import "ScanProgressPanelControl.h"

#import "TreeBuilder.h"
#import "FileItem.h"


@implementation ScanProgressPanelControl

- (id) init {
  if (self = [super initWithWindowNibName:@"ScanProgressPanel" owner:self]) {
    // Trigger loading of window.
    [self window];
  }
  
  return self;
}


- (void) dealloc {
  NSLog(@"ScanProgressPanelControl dealloc");
  NSAssert(treeBuilder == nil, @"TreeBuilder should be nil.");
  
  [super dealloc];  
}


- (IBAction) abort:(id)sender {
  [treeBuilder abort];
}


- (FileItem*) scanDirectory:(NSString*)dirName {
  NSDate  *startTime = [NSDate date];
  
  [progressText setStringValue:[NSString stringWithFormat:@"Scanning %@", 
                                           dirName]];
  [[self window] center];
  [[self window] orderFront:self];
  
  [progressIndicator startAnimation:nil];
  
  treeBuilder = [[TreeBuilder alloc] init];
  
  FileItem*  itemTreeRoot = [treeBuilder buildTreeForPath: dirName];
  
  [treeBuilder release];
  treeBuilder = nil;
  
  [progressIndicator stopAnimation:nil];
  NSLog(@"Done scanning. Total size=%qu, Time taken=%f", 
        [itemTreeRoot itemSize], -[startTime timeIntervalSinceNow]);
  
  [[self window] close];
  
  return itemTreeRoot;
}

@end
