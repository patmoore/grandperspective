#import <Cocoa/Cocoa.h>


extern NSString  *UniformTypesRankingKey;


@class UniformType;
@class UniformTypeInventory;

@interface UniformTypeRanking : NSObject {

  // Ordered list of all known types (UniformType)
  NSMutableArray  *rankedTypes;

}

+ (UniformTypeRanking *)defaultUniformTypeRanking;

/* Loads the ranking from the user preferences. It adds new types to the
 * type inventory as needed. This method should therefore not be invoked while 
 * another thread may also be using/modifying the inventory. 
 */
- (void) loadRanking: (UniformTypeInventory *)typeInventory;
- (void) storeRanking;

/* Observes the given type inventory for the addition of new types. These are
 * then automatically added at the end of the ranking.
 */
- (void) observeUniformTypeInventory: (UniformTypeInventory *)typeInventory;

- (NSArray *) uniformTypeRanking;

/* Updates the ranking of the uniform types.
 *
 * The types in the provided array should be a re-ordering of the types that 
 * were returned by an earlier call to -uniformTypeRanking (without a 
 * subsequent call to -updateUniformTypeRanking). As long as these constraints 
 * are obeyed this method correctly handles the appearance of new types (which
 * may have been created because new types were encountered during a scan in a
 * background thread). The provided ranking will be used, with any new types 
 * appended to the back.
 */
- (void) updateUniformTypeRanking: (NSArray *)ranking;

@end
