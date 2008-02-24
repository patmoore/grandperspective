#import <Cocoa/Cocoa.h>

#import "FileItemHashingScheme.h"


@class UniformTypeRanking;

@interface UniformTypeHashingScheme : NSObject <FileItemHashingScheme> {

  UniformTypeRanking  *typeRanking;

}

- (id) initWithUniformTypeRanking: (UniformTypeRanking *)typeRanking;

- (UniformTypeRanking *)uniformTypeRanking;

@end
