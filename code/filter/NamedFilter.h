#import <Cocoa/Cocoa.h>


@class Filter;

@interface NamedFilter : NSObject {
  Filter  *filter;
  NSString  *name;
}

+ (NamedFilter *)emptyFilterWithName:(NSString *)name;
+ (NamedFilter *)namedFilter:(Filter *)filter name:(NSString *)name;

- (id) initWithFilter:(Filter *)filter name:(NSString *)name;

- (Filter *)filter;
- (NSString *)name;
- (NSString *)localizedName;

@end
