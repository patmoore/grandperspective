#import <Cocoa/Cocoa.h>

@class FileItem;
@class PlainFileItem;
@protocol FileItemMappingScheme;

/* An implementation of a particular file item mapping scheme. It can map
 * file items to hash values.
 *
 * Implementations are not (necessarily) thread-safe. Each thread should get
 * an instance it can safely use by invoking -fileItemMapping on the file
 * item mapping scheme.
 */
@protocol FileItemMapping

- (NSObject <FileItemMappingScheme> *) fileItemMappingScheme;

/* Calculates a hash value for a file item in a tree, when the item is 
 * encountered while traversing the tree. The calculation may use the
 * "depth" of the file item relative to the root of the tree, as provided by
 * the TreeLayoutBuilder to the TreeLayoutTraverser.
 *
 * For calculating the hash value when not traversing a tree, use 
 * -hashForFileItem:inTree:.
 */
- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int)depth;

/* Calculates a hash value for a given file item in a tree. It performs the
 * same calculation as -hashForFileItem:depth:. Unlike the latter method, this 
 * one can be used when a tree is not being traversed (and the "depth" of the 
 * item is not easily available). The depth will be calculated relative to the
 * provided tree root.
 */
- (int) hashForFileItem: (PlainFileItem *)item inTree: (FileItem *)treeRoot;

/* Returns "YES" iff there are meaningful descriptions for each hash value.
 * In this case, the range of hash values is expected to be the consecutive 
 * numbers from zero upwards, as many as are needed. For each these values,
 * the method -descriptionForHash will provide a short descriptive string.
 */
- (BOOL) canProvideLegend;

@end


/* Informal protocol to be implemented by FileItemMapping schemes for which 
 * -canProvideLegend returns "YES".
 */
@interface LegendProvidingFileItemMapping

/* Short descriptive string for the given hash value. Returns "nil" if no
 * description can be given (i.e. when -canProvideLegend returns "NO"), or if
 * the hash value is outside of the valid range.
 */
- (NSString *) descriptionForHash: (int)hash;

- (NSString *) descriptionForRemainingHashes;

@end