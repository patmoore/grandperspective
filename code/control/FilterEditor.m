#import "FilterEditor.h"

#import "NameValidator.h"
#import "ModalityTerminator.h"
#import "NotifyingDictionary.h"

#import "Filter.h"
#import "NamedFilter.h"
#import "FilterRepository.h"

#import "EditFilterWindowControl.h"


@interface FilterNameValidator : NSObject <NameValidator> {
  NSDictionary  *allFilters;
  NSString  *allowedName;
}

- (id) initWithExistingFilters:(NSDictionary *)allFilters;
- (id) initWithExistingFilters:(NSDictionary *)allFilters 
         allowedName:(NSString *)name;

@end // @interface FilterNameValidator


@interface FilterEditor (PrivateMethods)

- (NSWindow *)loadEditFilterWindow;

@end // @interface FilterEditor (PrivateMethods)


@implementation FilterEditor

- (id) init {
  return [self initWithFilterRepository: [FilterRepository defaultInstance]];
}

- (id) initWithFilterRepository:(FilterRepository *)filterRepositoryVal {
  if (self = [super init]) {
    editFilterWindowControl = nil; // Load it lazily
  
    filterRepository = [filterRepositoryVal retain];
  }
  return self;
}

- (void) dealloc {
  [editFilterWindowControl release];

  [filterRepository release];
  
  [super dealloc];
}


- (NamedFilter *)newNamedFilter {
  NSWindow  *editFilterWindow = [self loadEditFilterWindow];
  
  FilterNameValidator  *nameValidator = 
    [[[FilterNameValidator alloc]
        initWithExistingFilters: [filterRepository filtersByName]]
          autorelease];
  
  [editFilterWindowControl setNameValidator: nameValidator];
  [editFilterWindowControl representEmptyFilter];

  [ModalityTerminator 
     modalityTerminatorForEventSource: editFilterWindowControl];
  int  status = [NSApp runModalForWindow: editFilterWindow];
  [editFilterWindow close];

  if (status == NSRunStoppedResponse) {
    NamedFilter  *namedFilter = [editFilterWindowControl createNamedFilter];
    
    if (namedFilter != nil) {
      NSString  *name = [namedFilter name];

      // The nameValidator should have ensured that this check succeeds.
      NSAssert( [[filterRepository filtersByName] objectForKey: name] == nil,
                @"Duplicate name check failed.");
      [[filterRepository filtersByNameAsNotifyingDictionary]
          addObject: [namedFilter filter] forKey: name];
        
      // Rest of addition handled in response to notification event.
    }
    
    return namedFilter;
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }    
}


- (NamedFilter *)editFilterNamed:(NSString *)oldName {
  NSWindow  *editFilterWindow = [self loadEditFilterWindow];

  Filter  *oldFilter = [[filterRepository filtersByName] objectForKey: oldName];

  NamedFilter  *oldNamedFilter = 
    [NamedFilter namedFilter: oldFilter name: oldName];
  [editFilterWindowControl representNamedFilter: oldNamedFilter];

  if ([filterRepository applicationProvidedFilterForName: oldName] != nil) {
    // The filter's name equals that of an application provided filter. Show 
    // the localized version of the name (which implicitly prevents the name
    // from being changed).  
    NSBundle  *mainBundle = [NSBundle mainBundle];
    NSString  *localizedName = 
      [mainBundle localizedStringForKey: oldName value: nil table: @"Names"];
      
    [editFilterWindowControl setVisibleName: localizedName];
  }
  
  FilterNameValidator  *testNameValidator = 
    [[[FilterNameValidator alloc]
        initWithExistingFilters: [filterRepository filtersByName]
          allowedName: oldName] autorelease];
  [editFilterWindowControl setNameValidator: testNameValidator];
  
  [ModalityTerminator
     modalityTerminatorForEventSource: editFilterWindowControl];
  int  status = [NSApp runModalForWindow: editFilterWindow];
  [editFilterWindow close];
    
  if (status == NSRunStoppedResponse) {
    NamedFilter  *newNamedFilter = [editFilterWindowControl createNamedFilter];
    
    if (newNamedFilter != nil) {
      NSString  *newName = [newNamedFilter name];
      NotifyingDictionary  *repositoryFiltersByName =
        [filterRepository filtersByNameAsNotifyingDictionary];

      // The testNameValidator should have ensured that this check succeeds.
      NSAssert( 
        [newName isEqualToString: oldName] ||
        [[filterRepository filtersByName] objectForKey: newName] == nil,
        @"Duplicate name check failed.");

      if (! [newName isEqualToString: oldName]) {
        // Handle name change.
        [repositoryFiltersByName moveObjectFromKey: oldName toKey: newName];
          
        // Rest of rename handled in response to update notification event.
      }
        
      // Filter itself has changed as well.
      Filter  *newFilter = [newNamedFilter filter];
      [repositoryFiltersByName updateObject: newFilter forKey: newName];      
    }
    
    return newNamedFilter;
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }
}

@end // @implementation FilterEditor


@implementation FilterEditor (PrivateMethods)

- (NSWindow *)loadEditFilterWindow {
  if (editFilterWindowControl == nil) {
    editFilterWindowControl = [[EditFilterWindowControl alloc] init];
  }
  // Return its window. This also ensure that it is loaded before its control 
  // is used.
  return [editFilterWindowControl window];
}

@end // @implementation FilterEditor (PrivateMethods)


@implementation FilterNameValidator

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithExistingFilters: instead.");
}

- (id) initWithExistingFilters:(NSDictionary *)allFiltersVal {
  return [self initWithExistingFilters: allFiltersVal allowedName: nil];
}

- (id) initWithExistingFilters:(NSDictionary *)allFiltersVal
         allowedName:(NSString *)name {
  if (self = [super init]) {
    allFilters = [allFiltersVal retain];
    allowedName = [name retain];    
  }
  
  return self;
}

- (void) dealloc {
  [allFilters release];
  [allowedName release];

  [super dealloc];
}


- (NSString *)checkNameIsValid:(NSString *)name {
  NSString*  errorText = nil;

  if ([name isEqualToString:@""]) {
    return NSLocalizedString(@"The filter must have a name.",
                             @"Alert message" );
  }
  else if ( ![allowedName isEqualToString: name] &&
            [allFilters objectForKey: name] != nil) {
    NSString  *fmt = NSLocalizedString(@"A filter named \"%@\" already exists.",
                                       @"Alert message");
    return [NSString stringWithFormat: fmt, name];
  }
  
  // All OK
  return nil;
}

@end // @implementation FilterNameValidator
