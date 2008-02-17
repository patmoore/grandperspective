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

- (NSSet *)childTypes;
- (void) addChildType: (UniformType *)childType;

- (BOOL) conformsToType: (UniformType *)type;

@end
