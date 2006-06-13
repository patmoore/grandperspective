#import "SaveImageDialogControl.h"

#import "DirectoryView.h"
#import "DirectoryViewControl.h"
#import "ItemTreeDrawer.h"
#import "ItemPathModel.h"
#import "FileItem.h"


@implementation SaveImageDialogControl

- (id) init {
  NSAssert(NO, @"Use -initWithDirectoryViewControl: instead");
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithDirectoryViewControl: (DirectoryViewControl*)dirViewControlVal {
         
  if (self = [super initWithWindowNibName:@"SaveImageDialog" owner:self]) {
    dirViewControl = [dirViewControlVal retain];
    
    // Trigger loading of window.
    [self window];
  }

  return self;
}

- (void) dealloc {
  NSLog(@"SaveImageDialogControl-dealloc");
  
  [dirViewControl release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  NSLog(@"windowDidLoad");

  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(windowWillClose:)
      name:@"NSWindowWillCloseNotification" object:[self window]];

  [[self window] center];
  [[self window] makeKeyAndOrderFront: self];

  NSRect  bounds = [[dirViewControl directoryView] bounds];
  [widthCell setIntValue: (int)bounds.size.width];
  [heightCell setIntValue: (int)bounds.size.height];
}


- (void) windowWillClose:(NSNotification*)notification {
   [self autorelease];
}


// Makes sure the width/height fields contain a (minimum) numeric value.
- (IBAction)valueEntered:(id)sender {
  int  value = [sender intValue];
  
  if (value < 16) {
    value = 16;
  }
  
  [sender setIntValue: value];
}


- (IBAction)cancelSaveImage:(id)sender {
  [[self window] close];
}
           
- (IBAction)saveImage:(id)sender {
  [[self window] close];

  // Retrieve the desired size of the image.  
  NSRect  bounds = 
            NSMakeRect(0, 0, [widthCell intValue], [heightCell intValue]);

  // Get a filename for the image.
  NSSavePanel  *savePanel = [NSSavePanel savePanel];  
  [savePanel setRequiredFileType: @"tiff"];
  
  if ([savePanel runModal] == NSOKButton) {
    NSString  *filename = [savePanel filename];
    
    // Draw the image.
    ItemTreeDrawer  *treeDrawer = [[[ItemTreeDrawer alloc] init] autorelease];
    [treeDrawer setFileItemHashing:[dirViewControl fileItemHashing]];
    NSImage  *image =
      [treeDrawer 
         drawImageOfItemTree: [[dirViewControl itemPathModel] visibleItemTree]
         inRect: bounds];
    
    // Save the image.
    NSBitmapImageRep  *imageBitmap = [[image representations] objectAtIndex:0];
    NSData  *imageData = [imageBitmap 
                            representationUsingType: NSTIFFFileType
                            properties: nil];
  
    if (! [imageData  writeToFile: filename atomically: NO] ) {
      NSAlert *alert = [[[NSAlert alloc] init] autorelease];
      [alert addButtonWithTitle:@"OK"];
      [alert setMessageText:@"Failed to save the image."];

      [alert runModal];
    }
  }
}


@end
