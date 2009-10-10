#import <Cocoa/Cocoa.h>


@interface LocalizableStrings : NSObject {

}

+ (NSString *) localizedAndEnumerationString:(NSArray *)items;

+ (NSString *) localizedOrEnumerationString:(NSArray *)items;
                 
+ (NSString *) localizedEnumerationString:(NSArray *)items
                 pairTemplate:(NSString *)pairTemplate
                 bootstrapTemplate:(NSString *)bootstrapTemplate
                 repeatingTemplate:(NSString *)repeatingTemplate;

@end
