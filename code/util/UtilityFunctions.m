#import "UtilityFunctions.h"


int stringCompare(id s1, id s2, void* context) {
  return [s1 compare: s2];
}
