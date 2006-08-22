#import "FileItem.h"

#import "DirectoryItem.h"


@interface FileItem (PrivateMethods)

- (NSMutableString*) mutableStringForFileItemPath;

@end


NSString* filesizeUnitString(int order) {
  switch (order) {
    case 0: return NSLocalizedString( @"kB", @"File size unit for kilobytes.");
    case 1: return NSLocalizedString( @"MB", @"File size unit for megabytes.");
    case 2: return NSLocalizedString( @"GB", @"File size unit for gigabytes.");
    case 3: return NSLocalizedString( @"TB", @"File size unit for terabytes.");
    default: return @""; // Should not happen, but cannot can NSAssert here.
  }
};


@implementation FileItem

// Overrides super's designated initialiser.
- (id) initWithItemSize:(ITEM_SIZE)sizeVal {
  return [self initWithName:@"" parent:nil size:sizeVal];
}

- (id) initWithName:(NSString*)nameVal parent:(DirectoryItem*)parentVal {
  return [self initWithName:nameVal parent:parentVal size:0];
}

- (id) initWithName:(NSString*)nameVal parent:(DirectoryItem*)parentVal
         size:(ITEM_SIZE)sizeVal {
  if (self = [super initWithItemSize:sizeVal]) {
    name = [nameVal retain];
    parent = parentVal; // not retaining it, as it is not owned.
  }
  return self;
}
  
- (void) dealloc {
  if (parent==nil) {
    NSLog(@"FileItem-dealloc (root)");
  }
  [name release];

  [super dealloc];
}


- (NSString*) description {
  return [NSString stringWithFormat:@"FileItem(%@, %qu)", name, size];
}


- (NSString*) name {
  return name;
}

- (DirectoryItem*) parentDirectory {
  return parent;
}

- (BOOL) isPlainFile {
  return YES;
}


- (NSString*) stringForFileItemPath {
  // Although the string could be made immutable before returning it, this is 
  // not done for performance. Furthermore, the returned string is only used by 
  // the callee, so who cares what he does with it...
  return [self mutableStringForFileItemPath];
}


+ (NSString*) stringForFileItemSize: (ITEM_SIZE)filesize {
  if (filesize < 1024) {
    // Definitely don't want a decimal point here
    NSString  *byteSizeUnit = NSLocalizedString( @"B", 
                                                 @"File size unit for bytes." );
    return [NSString stringWithFormat:@"%qu %@", filesize, byteSizeUnit];
  }

  double  n = (double)filesize / 1024;
  int  m = 0;
  // Note: The threshold for "n" is chosen to cope with rounding, ensuring
  // that the string for n = 1024^3 becomes "1.00 GB" instead of "1024 MB"
  while (n > 1023.999 && m < 3) {
    m++;
    n /= 1024; 
  }

  NSMutableString*  s = 
    [[[NSMutableString alloc] initWithCapacity:12] autorelease];
  [s appendFormat:@"%.2f", n];
  
  // Ensure that only the three most-significant digits are shown.
  // Exception: If there are four digits before the decimal point, all four
  // are shown.
  
  // TODO: Check that searching for "." is fully internationalizable.
  int  delPos = [s rangeOfString: @"."].location;
  if (delPos < 3) {
    // Keep one or more digits after the decimal point.
    delPos = 4;
  }
  else {
    // Keep all digits before the decimal point, drop the rest.
  }
  [s deleteCharactersInRange:NSMakeRange(delPos, [s length] - delPos)];

  [s appendFormat:@" %@", filesizeUnitString(m) ];

  return s;
}


+ (NSString*) exactStringForFileItemSize: (ITEM_SIZE)filesize {
  NSString  *format = NSLocalizedString( @"%qu bytes", 
                                         @"Exact file size (in bytes)." );

  return [NSString stringWithFormat: format, filesize ];
}


@end // @implementation FileItem


@implementation FileItem (PrivateMethods)

- (NSMutableString*) mutableStringForFileItemPath {
  NSMutableString*  s = 
    ((parent != nil) ? [parent mutableStringForFileItemPath]
                     : [NSMutableString stringWithCapacity:64]);

  if (! [self isPlainFile]) {
    [s appendString:name];
    [s appendString:@"/"];
  }
  // TODO: check if stringByAppendingPathComponent: can be used instead.
  
  return s;
}

@end