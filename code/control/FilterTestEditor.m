#import "FilterTestEditor.h"

#import "NameValidator.h"
#import "ModalityTerminator.h"
#import "NotifyingDictionary.h"

#import "FilterTest.h"
#import "FilterTestRepository.h"

#import "EditFilterTestWindowControl.h"


/* Performs a validity check on the name of filter tests (before the window is 
 * closed using the OK button).
 */
@interface FilterTestNameValidator : NSObject <NameValidator> {
  NSDictionary  *allTests;
  NSString  *allowedName;
}

- (id) initWithExistingTests:(NSDictionary *)allTests;
- (id) initWithExistingTests:(NSDictionary *)allTests 
         allowedName:(NSString *)name;

@end // @interface FilterTestNameValidator



@interface FilterTestEditor (PrivateMethods)

- (NSWindow *)loadEditFilterTestWindow;

@end // @interface FilterTestEditor (PrivateMethods)



@implementation FilterTestEditor

- (id) init {
  return [self initWithFilterTestRepository: 
                 [FilterTestRepository defaultInstance]];
}

- (id) initWithFilterTestRepository:(FilterTestRepository *)repository {
  if (self = [super init]) {
    editTestWindowControl = nil; // Load it lazily
  
    testRepository = [repository retain];
  }
  return self;
}

- (void) dealloc {
  [editTestWindowControl release];

  [testRepository release];
  
  [super dealloc];
}


- (FilterTest *)newFilterTest {
  NSWindow  *editTestWindow = [self loadEditFilterTestWindow];
  
  FilterTestNameValidator  *testNameValidator = 
    [[[FilterTestNameValidator alloc]
        initWithExistingTests: [testRepository testsByName]] autorelease];
  
  [editTestWindowControl setNameValidator: testNameValidator];
  [editTestWindowControl representFilterTest: nil];

  [ModalityTerminator modalityTerminatorForEventSource: editTestWindowControl];
  int  status = [NSApp runModalForWindow: editTestWindow];
  [editTestWindow close];

  if (status == NSRunStoppedResponse) {
    FilterTest  *filterTest = [editTestWindowControl createFilterTest];
    
    if (filterTest != nil) {
      NSString  *name = [filterTest name];

      // The nameValidator should have ensured that this check succeeds.
      NSAssert( 
        [[testRepository testsByName] objectForKey: name] == nil,
        @"Duplicate name check failed.");

      [[testRepository testsByNameAsNotifyingDictionary]
          addObject: [filterTest fileItemTest] forKey: name];
        
      // Rest of addition handled in response to notification event.
    }
    
    return filterTest;
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  
    return nil;
  }
}

- (FilterTest *)editFilterTestNamed:(NSString *)oldName {
  NSWindow  *editTestWindow = [self loadEditFilterTestWindow];

  FileItemTest  *oldTest = 
    [[testRepository testsByName] objectForKey: oldName];

  [editTestWindowControl representFilterTest: 
     [FilterTest filterTestWithName: oldName fileItemTest: oldTest]];

  if ([testRepository applicationProvidedTestForName: oldName] != nil) {
    // The test's name equals that of an application provided test. Show the
    // localized version of the name (which implicitly prevents the name from
    // being changed).
  
    NSBundle  *mainBundle = [NSBundle mainBundle];
    NSString  *localizedName = 
      [mainBundle localizedStringForKey: oldName value: nil table: @"Names"];
      
    [editTestWindowControl setVisibleName: localizedName];
  }
  
  FilterTestNameValidator  *testNameValidator = 
    [[[FilterTestNameValidator alloc]
        initWithExistingTests: [testRepository testsByName]
        allowedName: oldName] autorelease];
  
  [editTestWindowControl setNameValidator: testNameValidator];
  
  [ModalityTerminator modalityTerminatorForEventSource: editTestWindowControl];
  int  status = [NSApp runModalForWindow: editTestWindow];
  [editTestWindow close];
    
  if (status == NSRunStoppedResponse) {
    FilterTest  *newFilterTest = [editTestWindowControl createFilterTest];
    
    if (newFilterTest != nil) {
      NSString  *newName = [newFilterTest name];

      // The terminationControl should have ensured that this check succeeds.
      NSAssert( 
        [newName isEqualToString: oldName] ||
        [[testRepository testsByName] objectForKey: newName] == nil,
        @"Duplicate name check failed.");

      if (! [newName isEqualToString: oldName]) {
        // Handle name change.
        [[testRepository testsByNameAsNotifyingDictionary]
            moveObjectFromKey: oldName toKey: newName];
          
        // Rest of rename handled in response to update notification event.
      }
        
      // Test itself has changed as well.
      [[testRepository testsByNameAsNotifyingDictionary]
          updateObject: [newFilterTest fileItemTest] forKey: newName];

      // Rest of update handled in response to update notification event.
    }
    
    return newFilterTest;
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
    
    return nil;
  }
}

@end // @implementation FilterTestEditor


@implementation FilterTestEditor (PrivateMethods)

- (NSWindow *)loadEditFilterTestWindow {
  if (editTestWindowControl == nil) {
    editTestWindowControl = [[EditFilterTestWindowControl alloc] init];
  }
  // Return its window. This also ensure that it is loaded before its control 
  // is used.
  return [editTestWindowControl window];
}

@end // @implementation FilterTestEditor (PrivateMethods)


@implementation FilterTestNameValidator

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithExistingTests: instead.");
}

- (id) initWithExistingTests:(NSDictionary *)allTestsVal {
  return [self initWithExistingTests: allTestsVal allowedName: nil];
}

- (id) initWithExistingTests:(NSDictionary *)allTestsVal
         allowedName:(NSString *)name {
  if (self = [super init]) {
    allTests = [allTestsVal retain];
    allowedName = [name retain];    
  }
  
  return self;
}

- (void) dealloc {
  [allTests release];
  [allowedName release];

  [super dealloc];
}


- (NSString *)checkNameIsValid:(NSString *)name {
  NSString*  errorText = nil;

  if ([name isEqualToString:@""]) {
    return NSLocalizedString( @"The test must have a name.",
                              @"Alert message" );
  }
  else if ( ![allowedName isEqualToString: name] &&
            [allTests objectForKey: name] != nil) {
    NSString  *fmt = NSLocalizedString( @"A test named \"%@\" already exists.",
                                        @"Alert message" );
    return [NSString stringWithFormat: fmt, name];
  }
  
  // All OK
  return nil;
}

@end // @implementation FilterTestNameValidator