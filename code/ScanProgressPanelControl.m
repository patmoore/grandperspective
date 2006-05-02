#import "ScanProgressPanelControl.h"

#import "BalancedTreeBuilder.h"
#import "FileItem.h"


@implementation ScanProgressPanelControl

- (id) init {
  NSAssert(NO, @"Use -initWithCallBack:selector: instead");
}

- (id) initWithCallBack:(id)callBackVal selector:(SEL)selector {
  if (self = [super initWithWindowNibName:@"ScanProgressPanel" owner:self]) {
    callBack = [callBackVal retain];
    callBackSelector = selector;

    // Trigger loading of window.
    [self window];
  }
  
  return self;
}

- (void) dealloc {
  NSLog(@"ScanProgressPanelControl dealloc");
  NSAssert(treeBuilder == nil, @"TreeBuilder should be nil.");
  
  [callBack release];

  [super dealloc];  
}


- (IBAction) abort:(id)sender {
  [treeBuilder abort];
}


// Designed to be invoked in a separate thread.
- (void) scanDirectory:(NSString*)dirName {
  NSAutoreleasePool *pool;
  pool = [[NSAutoreleasePool alloc] init];
  
  NSDate  *startTime = [NSDate date];
  
  [progressText setStringValue:[NSString stringWithFormat:@"Scanning %@", 
                                           dirName]];
  [[self window] center];
  [[self window] orderFront:self];
  
  [progressIndicator startAnimation:nil];
  
  treeBuilder = [[BalancedTreeBuilder alloc] init];
  
  FileItem*  itemTreeRoot = [treeBuilder buildTreeForPath: dirName];
  
  [treeBuilder release];
  treeBuilder = nil;
  [dirName release];
  
  [progressIndicator stopAnimation:nil];
  NSLog(@"Done scanning. Total size=%qu, Time taken=%f", 
        [itemTreeRoot itemSize], -[startTime timeIntervalSinceNow]);
  
  [[self window] close];
 
  [callBack performSelector:callBackSelector withObject:itemTreeRoot];
  
  [pool release];  
}

@end
