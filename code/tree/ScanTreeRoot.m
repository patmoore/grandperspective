#import "ScanTreeRoot.h"


@interface ScanTreeRoot (PrivateMethods)

+ (NSString *)makeNameFriendly:(NSString *)systemName;

@end // @interface ScanTreeRoot (PrivateMethods)


@implementation ScanTreeRoot

// Overrides the designated initialiser
- (id) initWithName:(NSString *)systemNameVal parent:(DirectoryItem *)parentVal
         size:(ITEM_SIZE) sizeVal flags:(UInt8) flagsVal {
  if (self = [super initWithName: 
                        [ScanTreeRoot makeNameFriendly: systemNameVal]
                      parent: parentVal size: sizeVal flags: flagsVal]) {
    systemName = [systemNameVal retain];
  }
  return self;
}

- (void) dealloc {
  [systemName release];
  
  [super dealloc];
}

@end // @implementation ScanTreeRoot


@implementation ScanTreeRoot (ProtectedMethods)

- (NSString *)systemPathComponent {
  return systemName;
}

@end // @implementation ScanTreeRoot (ProtectedMethods)


@implementation ScanTreeRoot (PrivateMethods)

+ (NSString *)makeNameFriendly:(NSString *)systemName {
  NSMutableString  *name = [NSMutableString stringWithString: systemName];

  // Replace colons by slashes (to match representation in Finder)
  [name replaceOccurrencesOfString: @":" withString: @"/" 
          options: NSLiteralSearch range: NSMakeRange(0, [name length])]; 

  return [NSString stringWithString: name]; // Return immutable version
}

@end // @implementation ScanTreeRoot (PrivateMethods)
