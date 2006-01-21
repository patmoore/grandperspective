#import <Cocoa/Cocoa.h>


@class DirectoryViewControl;

// A one-shot image saving device. It disposes after having done its job.
@interface SaveImageDialogControl : NSWindowController {
  IBOutlet NSFormCell  *widthCell;
  IBOutlet NSFormCell  *heightCell;

  DirectoryViewControl  *dirViewControl;
}

- (id) initWithDirectoryViewControl: (DirectoryViewControl*)dirViewControl;

- (IBAction)valueEntered:(id)sender;
- (IBAction)cancelSaveImage:(id)sender;
- (IBAction)saveImage:(id)sender;

@end
