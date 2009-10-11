#import "AnnotatedTreeContext.h"

#import "TreeContext.h"

#import "FilterSet.h"
#import "FileItemTest.h"

@implementation AnnotatedTreeContext

+ (id) annotatedTreeContext:(TreeContext *)treeContext {
  return (treeContext == nil 
          ? nil
          : [[[AnnotatedTreeContext alloc] initWithTreeContext: treeContext] 
                 autorelease]);
}

+ (id) annotatedTreeContext:(TreeContext *)treeContext 
         comments:(NSString *)comments {
  return (treeContext == nil
          ? nil
          : [[[AnnotatedTreeContext alloc] 
                 initWithTreeContext: treeContext comments: comments] 
                   autorelease]);
}


- (id) initWithTreeContext:(TreeContext *)treeContextVal {
  FileItemTest  *test = [[treeContextVal filterSet] fileItemTest];

  return [self initWithTreeContext: treeContextVal
                 comments: ((test != nil) ? [test description] : @"")];
}

- (id) initWithTreeContext:(TreeContext *)treeContextVal
         comments:(NSString *)commentsVal {
  if (self = [super init]) {
    NSAssert(treeContextVal != nil, @"TreeContext must be set.");
  
    treeContext = [treeContextVal retain];
    
    // Create a copy of the string, to ensure it is immutable.
    comments = (commentsVal != nil 
                ? [[NSString stringWithString: commentsVal] retain]
                : @"");
  }
  return self;
}


- (TreeContext *)treeContext {
  return treeContext;
}

- (NSString *)comments {
  return comments;
}

@end
