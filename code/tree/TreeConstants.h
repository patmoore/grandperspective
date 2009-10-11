
/* Initial capacity for arrays that will be used to store all files in a given
 * directory. It is chosen such that for a scan of my own HD (taken without 
 * root priviliges) the initial capacity is sufficient 97.8% of the time.
 */
#define  INITIAL_FILES_CAPACITY  32

/* Initial capacity for arrays that will be used to store all directories in a 
 * given directory. It is chosen such that for a scan of my own HD (taken
 * without root priviliges) the initial capacity is sufficient 97.4% of the
 * time.
 */
#define  INITIAL_DIRS_CAPACITY    8
