#import <Cocoa/Cocoa.h>


@class TreeContext;


/* A tree context with additional text comments that allow human-readable
 * information to be associated with the scan data. The comments can be used by 
 * the application to document the use of a filter, but also for the user to 
 * provide further background information with respect to the scan, e.g. "My 
 * harddrive just before upgrading to Snow Leopard".
 */
@interface AnnotatedTreeContext : NSObject {
  TreeContext  *treeContext;
  NSString  *comments;
}

+ (id) annotatedTreeContext:(TreeContext *)treeContext; 
+ (id) annotatedTreeContext:(TreeContext *)treeContext 
         comments: (NSString *)comments;

- (id) initWithTreeContext:(TreeContext *)treeContext;
- (id) initWithTreeContext:(TreeContext *)treeContext 
         comments:(NSString *)comments;

- (TreeContext *) treeContext;
- (NSString *) comments;

@end
