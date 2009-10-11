#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


/**
 * A test that applies to only files or only folders, but not both.
 */
@interface SelectiveItemTest : FileItemTest {

  FileItemTest  *subTest;

  // Controls if the subtest targets only files or only folders.
  BOOL  onlyFiles;

}

- (id) initWithSubItemTest:(FileItemTest *)subTest onlyFiles:(BOOL) onlyFiles;


- (FileItemTest *)subItemTest;

/**
 * Returns yes if "YES" the subtest is only be applied to files; otherwise the
 * subtest is only applied to folders.
 */
- (BOOL) applyToFilesOnly;


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
