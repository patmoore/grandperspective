#import <Cocoa/Cocoa.h>

#import "AbstractFileItemTest.h"

/**
 * A test that applies to only files or only folders, but not both.
 */
@interface SelectiveItemTest : AbstractFileItemTest {

  NSObject <FileItemTest>  *subTest;

  // Controls if the subtest targets only files or only folders.
  BOOL  onlyFiles;

}

- (id) initWithSubItemTest: (NSObject<FileItemTest> *)subTest 
         onlyFiles: (BOOL) onlyFiles;


- (NSObject <FileItemTest> *) subItemTest;

/**
 * Returns yes if "YES" the subtest is only be applied to files; otherwise the
 * subtest is only applied to folders.
 */
- (BOOL) applyToFilesOnly;


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict;

@end
