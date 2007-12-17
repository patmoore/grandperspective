#import "NotifyingPanel.h"


NSString  *FirstResponderChangedEvent = @"firstResponderChanged";


@interface NotifyingPanel (PrivateMethods) 

- (void) windowFirstResponderChanged_: (NSNotification*) notification;

@end


@implementation NotifyingPanel

// Overrides designated initialiser
- (id)initWithContentRect: (NSRect)contentRect 
       styleMask: (unsigned int)styleMask 
       backing: (NSBackingStoreType)backingType 
       defer: (BOOL)flag {
  if (self = [super initWithContentRect: contentRect styleMask: styleMask
                      backing: backingType defer: flag]) {
    [[NSNotificationCenter defaultCenter]
        addObserver: self selector: @selector(windowFirstResponderChanged_:) 
          name: FirstResponderChangedEvent object: self];
  }
  return self;
}


- (BOOL) makeFirstResponder: (NSResponder *)aResponder {
  BOOL  retVal = [super makeFirstResponder: aResponder];

  // Note: Using notification queue here to exploit coalescing behaviour.
  // Sometimes a single click can trigger multiple calls to makeFirstResponder.
  // This is for instance the case when clicking on an instance of NSBrowser.
  // In this case it's nice to only call the delegate once, instead of 
  // multiple times.
  //
  // Note: We should never call the delegate directly from here. The OS 
  // should be given time to finish changing the first responder; there's still
  // more to do after -makeFirstResponder: gets called. So we should either
  // post the notification via the notification queue with a posting style of 
  // NSPostASAP (as is done here). Or alternatively, call the delegate method
  // with -performSelector:withObject:afterDelay:0. [Source: post on 
  // Apple Mailing list by Dustin Voss, dd. 30 Mar 2004].

  NSNotification  *notification = 
    [NSNotification notificationWithName: FirstResponderChangedEvent
                      object: self];

  [[NSNotificationQueue defaultQueue]
     enqueueNotification: notification 
     postingStyle: NSPostASAP
     coalesceMask: (NSNotificationCoalescingOnName | 
                    NSNotificationCoalescingOnSender)
     forModes: nil];

  return retVal;
}


- (void) windowFirstResponderChanged: (NSNotification*) notification {
  // void - can be overridden.
}

@end


@implementation NotifyingPanel (PrivateMethods)

- (void) windowFirstResponderChanged_: (NSNotification*) notification {
  SEL  sel = @selector(windowFirstResponderChanged:);
  id  target = ([[self delegate] respondsToSelector: sel] 
                  ? [self delegate] : self);

  // Notify the delegate (if it exists and has implemented the method). 
  // Otherwise just call own method, which can then be overriden if need be.
  [target performSelector: sel withObject: notification];
}

@end
