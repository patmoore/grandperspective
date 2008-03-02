#import <Cocoa/Cocoa.h>

#import "FileItemMappingScheme.h"


@class UniformTypeRanking;

@interface UniformTypeMappingScheme : NSObject <FileItemMappingScheme> {

  UniformTypeRanking  *typeRanking;

}

- (id) initWithUniformTypeRanking: (UniformTypeRanking *)typeRanking;

- (UniformTypeRanking *)uniformTypeRanking;

@end
