#import "FileItem.h"


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

@end // @implementation FileItem