#import "DirectoryItem.h"



@interface SpecialDirectoryItem : DirectoryItem {
}
@end

@implementation SpecialDirectoryItem
- (BOOL) isSpecial { return YES; }
@end


@implementation DirectoryItem

+ (DirectoryItem *)specialDirectoryItemWithName:(NSString *)nameVal
                     parent:(DirectoryItem *)parentVal {
  return [[[SpecialDirectoryItem alloc] initWithName: nameVal 
                                          parent: parentVal] autorelease];
}


- (void) dealloc {
  [contents release];

  [super dealloc];
}


- (void) setDirectoryContents:(Item *)contentsVal {
  NSAssert(contents == nil, @"Contents should only be set once.");
  
  contents = [contentsVal retain];
  size = (contents == nil) ? 0 : [contents itemSize];
}


- (NSString*) description {
  return [NSString stringWithFormat:@"DirectoryItem(%@, %qu, %@)", name, size,
                     [contents description]];
}


- (BOOL) isPlainFile {
  return NO;
}

- (Item*) getContents {
  return contents;
}

@end
