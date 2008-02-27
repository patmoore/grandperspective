#import <Cocoa/Cocoa.h>

/* Event that signals that the (relative) order of two or more uniform types
 * changes.
 *
 * Note: This event is not fired when new types are added at the end of the
 * ranking.
 */
extern NSString  *UniformTypeRankingChangedEvent;

/* The key that is used to store the ranking in the user preferences.
 */
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
 * then automatically added at the end of the ranking. Furthermore, any types
 * in the inventory that are not yet in the ranking, are added (to the end).
 */
- (void) observeUniformTypeInventory: (UniformTypeInventory *)typeInventory;

- (NSArray *) rankedUniformTypes;

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
- (void) updateRankedUniformTypes: (NSArray *)ranking;


/* Returns YES if the given type is dominated. A type is considered dominated
 * if one of the types is conforms to (directly or indirectly) appears higher
 * in the list than the type itself.
 *
 * Note: Should the specified type not actually be the list, then this method
 * acts as if it resides at the bottom of the list. I.e. it return YES if the 
 * type is dominated by any type in the list.
 *
 * Note: This method checks dynamically if a given type is dominated, so it
 * should be invoked with a bit of care.
 */
- (BOOL) isUniformTypeDominated: (UniformType *)type;

/* Returns the ranked list of types, excluding those that are dominated. See
 * also -isUniformTypeDominated:.
 *
 * Note: This list is calculated dynamically, so it should be invoked with a
 * little bit of care.
 */
- (NSArray *) undominatedRankedUniformTypes;

@end
