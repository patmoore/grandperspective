#import <Cocoa/Cocoa.h>


// Note: Instances are immutable (and as a result, the class is thread-safe). 
@interface UniformType : NSObject {
  NSString*  uti;
  NSString*  description;

  // An immutable set of "UniformType"s
  NSSet*  parents;
}


- (id) initWithUniformTypeIdentifier: (NSString *)uti
         description: (NSString *)description
         parents: (NSArray *)parentTypes;

- (NSString *)uniformTypeIdentifier;

- (NSString *)description;

- (NSSet *)parentTypes;

// Calculated dynamically (so should be invoked with a bit of care)
- (NSSet *)ancestorTypes;

@end
