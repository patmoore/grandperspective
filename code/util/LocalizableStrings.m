#import "LocalizableStrings.h"


@interface LocalizableStrings (PrivateMethods)

+ (NSString *) localizedEnumerationString:(NSArray *)items
                 pairTemplate:(NSString *)pairTemplate
                 bootstrapTemplate:(NSString *)bootstrapTemplate;

@end // @interface LocalizableStrings (PrivateMethods)


@implementation LocalizableStrings

+ (NSString *) localizedAndEnumerationString:(NSArray *)items {
  NSString  *pairTemplate =
    NSLocalizedString(@"%@ and %@", @"Enumeration of two items");
  NSString  *bootstrapTemplate =
    NSLocalizedString(@"%@, and %@",
    @"Enumeration of three or more items with 1: two or more items, 2: last item");
  return [self localizedEnumerationString: items
                 pairTemplate: pairTemplate
                 bootstrapTemplate: bootstrapTemplate];
}

+ (NSString *) localizedOrEnumerationString:(NSArray *)items {
  NSString  *pairTemplate =
    NSLocalizedString(@"%@ or %@", @"Enumeration of two items");
  NSString  *bootstrapTemplate =
    NSLocalizedString(@"%@, or %@",
    @"Enumeration of three or more items with 1: two or more items, 2: last item");
  return [self localizedEnumerationString: items
                 pairTemplate: pairTemplate
                 bootstrapTemplate: bootstrapTemplate];
}

+ (NSString *) localizedEnumerationString:(NSArray *)items
                 pairTemplate:(NSString *)pairTemplate
                 bootstrapTemplate:(NSString *)bootstrapTemplate
                 repeatingTemplate:(NSString *)repeatingTemplate {
  if ([items count] == 0) {
    return @"";
  }
  else if ([items count] == 1) {
    return [items objectAtIndex: 0];
  }
  else if ([items count] == 2) {
    return [NSString stringWithFormat: pairTemplate, [items objectAtIndex: 0],
                                         [items objectAtIndex: 1]];
  }
  else {
    NSEnumerator  *itemEnum = [items reverseObjectEnumerator];

    NSString  *item = [itemEnum nextObject]; // Last item
    NSString  *s =
      [NSString stringWithFormat: bootstrapTemplate, [itemEnum nextObject], item];

    while ( item = [itemEnum nextObject] ) {
      s = [NSString stringWithFormat: repeatingTemplate, item, s];
    }
    
    return s;
  }
}

@end // @implementation LocalizableStrings


@implementation LocalizableStrings (PrivateMethods)

+ (NSString *) localizedEnumerationString:(NSArray *)items
                 pairTemplate:(NSString *)pairTemplate
                 bootstrapTemplate:(NSString *)bootstrapTemplate {
  NSString  *repeatingTemplate =
    NSLocalizedString(@"%@, %@", 
      @"Enumeration of three or more items with 1: an item, 2: two or more items");
  return [self localizedEnumerationString: items
                 pairTemplate: pairTemplate
                 bootstrapTemplate: bootstrapTemplate
                 repeatingTemplate: repeatingTemplate];
}

@end // @implementation LocalizableStrings (PrivateMethods)

