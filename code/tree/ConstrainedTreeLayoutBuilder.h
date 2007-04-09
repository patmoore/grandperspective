#import <Cocoa/Cocoa.h>

#import "TreeLayoutBuilder.h"


// A layout builder that is constrained to leave a certain proportion of the
// area empty. 
@interface ConstrainedTreeLayoutBuilder : TreeLayoutBuilder {
  unsigned long long  reservedSpace;
}

- (id) initWithReservedSpace: (unsigned long long) reservedSpace;

- (unsigned long long) reservedSpace;

@end
