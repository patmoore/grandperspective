#import <Cocoa/Cocoa.h>


@class UniformTypeInventory;

@interface UniformType : NSObject {
  NSString*  uti;
  NSString*  description;

  // An immutable set of "UniformType"s
  NSSet*  parents;

  // An immutable set of "UniformType"s
  NSSet*  children;
}


- (id) initWithUniformTypeIdentifier: (NSString *)uti;
- (id) initWithUniformTypeIdentifier: (NSString *)uti 
         inventory: (UniformTypeInventory *)inventory;

- (NSString *)uniformTypeIdentifier;

- (NSString *)description;

- (NSSet *)parentTypes;

// Calculated dynamically (so should be invoked with a bit of care)
- (NSSet *)ancestorTypes;

- (NSSet *)childTypes;
- (void) addChildType: (UniformType *)childType;

@end
