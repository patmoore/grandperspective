#import <Cocoa/Cocoa.h>

@class PlainFileItem;
@protocol FileItemHashingScheme;

/* An implementation of a particular file item hashing scheme. It can derive
 * hash values for file items.
 *
 * Implementations are not (necessarily) thread-safe. Each thread should get
 * an instance it can safely use by invoking -fileItemHashing on the file
 * item hashing scheme.
 */
@protocol FileItemHashing

- (NSObject <FileItemHashingScheme> *) fileItemHashingScheme;

- (int) hashForFileItem: (PlainFileItem *)item depth: (int)depth;

/* Returns "YES" iff there are meaningful descriptions for each hash value.
 * In this case, the range of hash values is expected to be the consecutive 
 * numbers from zero upwards, as many as are needed. For each these values,
 * the method -descriptionForHash will provide a short descriptive string.
 */
- (BOOL) canProvideLegend;

/* Short descriptive string for the given hash value. Returns "nil" if no
 * description can be given (i.e. when -canProvideLegend returns "NO"), or if
 * the hash value is outside of the valid range.
 */
- (NSString *) descriptionForHash: (int)hash;

- (NSString *) descriptionForRemainingHashes;

@end
