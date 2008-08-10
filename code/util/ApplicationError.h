#import <Cocoa/Cocoa.h>


/* Error that signals recoverable errors at the application level, e.g. 
 * failure to open a file. It is not intended for critical errors, e.g. 
 * assertion failures due to bugs.
 */
@interface ApplicationError : NSError {

}

- (id) initWithLocalizedDescription: (NSString *)descr;
- (id) initWithCode: (int)code localizedDescription: (NSString *)descr;
- (id) initWithCode: (int)code userInfo: (NSDictionary *)userInfo;

+ (id) errorWithLocalizedDescription: (NSString *)descr;
+ (id) errorWithCode: (int)code localizedDescription: (NSString *)descr;
+ (id) errorWithCode: (int)code userInfo: (NSDictionary *)userInfo;

@end
