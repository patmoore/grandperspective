#import <Cocoa/Cocoa.h>


@interface ModalityTerminator : NSObject {
}

+ (ModalityTerminator *)modalityTerminatorForEventSource:(NSObject *)source;

- (id) initWithEventSource:(NSObject *)eventSource;

- (void) abortModalAction:(NSNotification *)notification;
- (void) stopModalAction:(NSNotification *)notification;

@end
