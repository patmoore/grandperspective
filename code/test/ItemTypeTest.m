#import "ItemTypeTest.h"

#import "TestDescriptions.h"
#import "PlainFileItem.h"
#import "FileItemTestVisitor.h"
#import "UniformType.h"
#import "UniformTypeInventory.h"


@interface ItemTypeTest (PrivateMethods)

- (NSArray *) matchesAsStrings;

@end


@implementation ItemTypeTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithMatchTargets: instead.");
}

- (id) initWithMatchTargets: (NSArray *)matchesVal {
  return [self initWithMatchTargets: matchesVal strict: NO];
}

- (id) initWithMatchTargets: (NSArray *)matchesVal strict: (BOOL) strictVal {
  if (self = [super init]) {
    // Make the array immutable
    matches = [[NSArray alloc] initWithArray: matchesVal];

    strict = strictVal;
  }
  
  return self;
}


- (void) dealloc {
  [matches release];
  
  [super dealloc];
}


// Note: Special case. Does not call own designated initialiser. It should
// be overridden and only called by initialisers with the same signature.
- (id) initWithPropertiesFromDictionary: (NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSArray  *utis = [dict objectForKey: @"matches"];
    unsigned  numMatches = [utis count];

    UniformTypeInventory  *typeInventory = 
      [UniformTypeInventory defaultUniformTypeInventory];

    NSMutableArray  *tmpMatches =
      [NSMutableArray arrayWithCapacity: numMatches];
    
    unsigned  i = 0;
    while (i < numMatches) {
      UniformType  *type = 
        [typeInventory uniformTypeForIdentifier: [utis objectAtIndex: i]];
        
      if (type != nil) {
        [tmpMatches addObject: type];
      }
      
      i++;
    }
    
    // Make the array immutable
    matches = [[NSArray alloc] initWithArray: tmpMatches];
    
    strict = [[dict objectForKey: @"strict"] boolValue];
  }
  
  return self;
}


- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"ItemTypeTest" forKey: @"class"];
  
  UniformTypeInventory  *typeInventory = 
    [UniformTypeInventory defaultUniformTypeInventory];

  [dict setObject: [self matchesAsStrings] forKey: @"matches"];  
  [dict setObject: [NSNumber numberWithBool: strict] forKey: @"strict"];
}


- (NSArray *) matchTargets {
  return matches;
}

- (BOOL) isStrict {
  return strict;
}


- (TestResult) testFileItem: (FileItem *)item context: (id)context {
  if ([item isDirectory]) {
    // Test does not apply to directories
    return TEST_NOT_APPLICABLE;
  }
  
  UniformType  *type = [((PlainFileItem *)item) uniformType];
  NSSet  *ancestorTypes = strict ? nil : [type ancestorTypes];
    
  int  i = [matches count];
  while (--i >= 0) {
    UniformType  *matchType = [matches objectAtIndex: i];
    if (type == matchType || [ancestorTypes containsObject: matchType]) {
      return TEST_PASSED;
    }
  }
  
  return TEST_FAILED;
}

- (BOOL) appliesToDirectories {
  return NO;
}

- (void) acceptFileItemTestVisitor: (NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitItemTypeTest: self];
}


- (NSString *) description {
  NSString  *matchesDescr = descriptionForMatches( [self matchesAsStrings] );
  NSString  *format = ( strict 
                        ? NSLocalizedStringFromTable( 
                            @"type equals %@", @"Tests",
                            @"Filetype test with 1: match targets" )
                        : NSLocalizedStringFromTable( 
                            @"type conforms to %@", @"Tests",
                            @"Filetype test with 1: match targets" ) );
  
  return [NSString stringWithFormat: format, matchesDescr];
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {  
  NSAssert([[dict objectForKey: @"class"] isEqualToString: @"ItemTypeTest"],
             @"Incorrect value for class in dictionary.");

  return [[[ItemTypeTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end


@implementation ItemTypeTest (PrivateMethods)

- (NSArray *) matchesAsStrings {
  unsigned  numMatches = [matches count];
  NSMutableArray  *utis = [NSMutableArray arrayWithCapacity: numMatches];

  unsigned  i = 0;
  while (i < numMatches) {
    [utis addObject: 
       [((UniformType *)[matches objectAtIndex: i]) uniformTypeIdentifier]];
    i++;
  }
  
  return utis;
}

@end // @implementation ItemTypeTest (PrivateMethods)

