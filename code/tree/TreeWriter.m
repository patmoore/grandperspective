#import "TreeWriter.h"

#import "DirectoryItem.h"
#import "CompoundItem.h"

#import "TreeContext.h"
#import "AnnotatedTreeContext.h"

#import "FilterTest.h"
#import "FileItemFilter.h"
#import "FileItemFilterSet.h"

#import "ProgressTracker.h"

#import "ApplicationError.h"


#define  BUFFER_SIZE  4096

NSString  *TreeWriterFormatVersion = @"2";

// XML elements
NSString  *ScanDumpElem = @"GrandPerspectiveScanDump";
NSString  *ScanInfoElem = @"ScanInfo";
NSString  *ScanCommentsElem = @"ScanComments";
NSString  *FilterSetElem = @"FilterSet";
NSString  *FilterElem = @"Filter";
NSString  *FilterTestElem = @"FilterTest";
NSString  *FolderElem = @"Folder";
NSString  *FileElem = @"File";

// XML attributes of GrandPerspectiveScanDump
NSString  *AppVersionAttr = @"appVersion";
NSString  *FormatVersionAttr = @"formatVersion";

// XML attributes of GrandPerspectiveScanInfo
NSString  *VolumePathAttr = @"volumePath";
NSString  *VolumeSizeAttr = @"volumeSize";
NSString  *FreeSpaceAttr = @"freeSpace";
NSString  *ScanTimeAttr = @"scanTime";
NSString  *FileSizeMeasureAttr = @"fileSizeMeasure";

// XML attributes of FilterTest
NSString  *InvertedAttr = @"inverted";

// XML attributes of Folder and File
NSString  *NameAttr = @"name";
NSString  *FlagsAttr = @"flags";
NSString  *SizeAttr = @"size";

// XML attribute values
NSString  *TrueValue = @"true";
NSString  *FalseValue = @"false";

// Localized error messages
#define WRITING_LAST_DATA_FAILED \
   NSLocalizedString(@"Failed to write last data to file.", @"Error message")
#define WRITING_BUFFER_FAILED \
   NSLocalizedString(@"Failed to write entire buffer.", @"Error message")


#define  CHAR_AMPERSAND    0x01
#define  CHAR_LESSTHAN     0x02
#define  CHAR_DOUBLEQUOTE  0x04

#define  ATTRIBUTE_ESCAPE_CHARS  (CHAR_AMPERSAND | CHAR_LESSTHAN \
                                  | CHAR_DOUBLEQUOTE)
#define  CHARDATA_ESCAPE_CHARS   (CHAR_AMPERSAND | CHAR_LESSTHAN)


/* Escapes the string so that it can be used a valid XML attribute value or
 * valid XML character data. The characters that are escaped are specified by
 * a mask, which must reflect the context where the string is to be used.
 */
NSString *escapedXML(NSString *s, int escapeCharMask) {
  // Lazily construct buffer. Only use it when needed.
  NSMutableString  *buf = nil;
  
  int  i;
  int  numCharsInVal = [s length];
  int  numCharsInBuf = 0;
  
  for (i = 0; i < numCharsInVal; i++) {
    unichar  c = [s characterAtIndex: i];
    NSString  *r = nil;
    if (c == '&' && (escapeCharMask & CHAR_AMPERSAND)!=0 ) {
      r = @"&amp;";
    }
    else if (c == '<' && (escapeCharMask & CHAR_LESSTHAN)!=0 ) {
      r = @"&lt;";
    }
    else if (c== '"' && (escapeCharMask & CHAR_DOUBLEQUOTE)!=0) {
      r = @"&quot;";
    }
    if (r != nil) {
      if (buf == nil) {
        buf = [NSMutableString stringWithCapacity: numCharsInVal * 2];
      }

      if (numCharsInBuf < i) {
        // Copy preceding characters that did not require escaping to buffer
        [buf appendString: [s substringWithRange:
                                NSMakeRange(numCharsInBuf,
                                            i - numCharsInBuf)]];
        numCharsInBuf = i;
      }
      
      [buf appendString: r];
      numCharsInBuf++;
    }
  }
  
  if (buf == nil) {
    // String did not contain an characters that needed escaping
    return s;
  }
  
  if (numCharsInBuf < numCharsInVal) {
    // Append final characters to buffer
    [buf appendString: [s substringWithRange: 
                            NSMakeRange(numCharsInBuf,
                                        numCharsInVal - numCharsInBuf)]];
    numCharsInBuf = numCharsInVal;
  }
  
  return buf;
}


@interface TreeWriter (PrivateMethods) 

- (void) appendScanDumpElement: (AnnotatedTreeContext *)tree;
- (void) appendScanInfoElement: (AnnotatedTreeContext *)tree;
- (void) appendScanCommentsElement: (NSString *)comments;
- (void) appendFilterSetElement: (FileItemFilterSet *)filterSet;
- (void) appendFilterElement: (FileItemFilter *)filter;
- (void) appendFilterTestElement: (FilterTest *)filterTest;
- (void) appendFolderElement: (DirectoryItem *)dirItem;
- (void) appendFileElement: (FileItem *)fileItem;

- (void) dumpItemContents: (Item *)item;

- (void) appendString: (NSString *)s;

@end


@implementation TreeWriter

- (id) init {
  if (self = [super init]) {
    dataBuffer = malloc(BUFFER_SIZE);

    abort = NO;
    error = nil;
    
    progressTracker = [[ProgressTracker alloc] init];
  }
  return self;
}

- (void) dealloc {
  free(dataBuffer);
  
  [error release];

  [progressTracker release];
  
  [super dealloc];
}


- (BOOL) writeTree: (AnnotatedTreeContext *)tree toFile: (NSString *)filename {
  NSAssert(file == NULL, @"File not NULL");

  [progressTracker startingTask];
  
  file = fopen( [filename UTF8String], "w");
  if (file == NULL) {
    return NO;
  }

  dataBufferPos = 0;

  [self appendString: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
  [self appendScanDumpElement: tree];
  
  if (error==nil && dataBufferPos > 0) {
    // Write remaining characters in buffer
    unsigned  numWritten = fwrite( dataBuffer, 1, dataBufferPos, file );
    
    if (numWritten != dataBufferPos) {
      NSLog(@"Failed to write last data: %d bytes written out of %d.", 
                numWritten, dataBufferPos);

      error = [[ApplicationError alloc] initWithLocalizedDescription: 
                  WRITING_LAST_DATA_FAILED];
    }
  }
  
  fclose(file);
  file = NULL;
  
  [progressTracker finishedTask];
  
  return (error==nil) && !abort;
}

- (void) abort {
  abort = YES;
}

- (BOOL) aborted {
  return (error==nil) && abort;
}

- (NSError *) error {
  return error;
}

- (NSDictionary *) progressInfo {
  return [progressTracker progressInfo];
}

@end


@implementation TreeWriter (PrivateMethods) 

- (void) appendScanDumpElement: (AnnotatedTreeContext *)annotatedTree {
  NSString  *appVersion =
    [[[NSBundle mainBundle] infoDictionary] objectForKey: 
                                              @"CFBundleVersion"];

  [self appendString: 
    [NSString stringWithFormat: @"<%@ %@=\"%@\" %@=\"%@\">\n", 
       ScanDumpElem, 
       AppVersionAttr, appVersion, 
       FormatVersionAttr, TreeWriterFormatVersion]];
  
  [self appendScanInfoElement: annotatedTree];
  
  [self appendString: [NSString stringWithFormat: @"</%@>\n", ScanDumpElem]];
}


- (void) appendScanInfoElement: (AnnotatedTreeContext *)annotatedTree {
  TreeContext  *tree = [annotatedTree treeContext];

  [self appendString: 
     [NSString stringWithFormat: 
        @"<%@ %@=\"%@\" %@=\"%qu\" %@=\"%qu\" %@=\"%@\" %@=\"%@\">\n", 
        ScanInfoElem, 
        VolumePathAttr, escapedXML( [[tree volumeTree] name], 
                                    ATTRIBUTE_ESCAPE_CHARS ),
        VolumeSizeAttr, [tree volumeSize],
        FreeSpaceAttr, ([tree freeSpace] + [tree freedSpace]),
        ScanTimeAttr, [[tree scanTime] description],
        FileSizeMeasureAttr, [tree fileSizeMeasure]]];
  
  [self appendScanCommentsElement: [annotatedTree comments]];
  [self appendFilterSetElement: [tree filterSet]];
  
  [tree obtainReadLock];
  [self appendFolderElement: [tree scanTree]];
  [tree releaseReadLock];
  
  [self appendString: [NSString stringWithFormat: @"</%@>\n", ScanInfoElem]];
}


- (void) appendScanCommentsElement: (NSString *)comments {
  if ([comments length] == 0) {
    return;
  }

  [self appendString: 
     [NSString stringWithFormat: @"<%@>%@</%@>\n",
        ScanCommentsElem,
        escapedXML(comments, CHARDATA_ESCAPE_CHARS),
        ScanCommentsElem]];
}


- (void) appendFilterSetElement: (FileItemFilterSet *)filterSet {
  if ([filterSet numFileItemFilters] == 0) {
    return;
  }
  
  [self appendString: [NSString stringWithFormat: @"<%@>\n", FilterSetElem]];

  NSEnumerator  *filterEnum = [[filterSet fileItemFilters] objectEnumerator];
  FileItemFilter  *filter;
  while (filter = [filterEnum nextObject]) {
    [self appendFilterElement: filter];
  }

  [self appendString: [NSString stringWithFormat: @"</%@>\n", FilterSetElem]];
}


- (void) appendFilterElement: (FileItemFilter *)filter {
  if ([filter numFilterTests] == 0) {
    return;
  }
  
  NSString  *nameVal = escapedXML([filter name], ATTRIBUTE_ESCAPE_CHARS);
  [self appendString: 
          [NSString stringWithFormat: @"<%@ %@=\"%@\">\n", 
                      FilterElem,
                      NameAttr, nameVal]];

  NSEnumerator  *testEnum = [[filter filterTests] objectEnumerator];
  FilterTest  *filterTest;
  while (filterTest = [testEnum nextObject]) {
    [self appendFilterTestElement: filterTest];
  }

  [self appendString: [NSString stringWithFormat: @"</%@>\n", FilterElem]];
}


- (void) appendFilterTestElement: (FilterTest *)filterTest {
  NSString  *nameVal = escapedXML([filterTest name], ATTRIBUTE_ESCAPE_CHARS);
  [self appendString: 
          [NSString stringWithFormat: @"<%@ %@=\"%@\" %@=\"%@\" />\n", 
                      FilterTestElem, 
                      NameAttr, nameVal,
                      InvertedAttr,
                      ([filterTest isInverted] ? TrueValue : FalseValue) ]];
}


- (void) appendFolderElement: (DirectoryItem *)dirItem {
  [progressTracker processingFolder: dirItem];

  NSString  *nameVal = escapedXML([dirItem name], ATTRIBUTE_ESCAPE_CHARS);
  [self appendString: 
          ( ([dirItem fileItemFlags] != 0) 
            ? [NSString stringWithFormat:
                          @"<%@ %@=\"%@\" %@=\"%d\">\n", 
                          FolderElem,
                          NameAttr, nameVal, 
                          FlagsAttr, [dirItem fileItemFlags]]
            : [NSString stringWithFormat:
                          @"<%@ %@=\"%@\">\n", 
                          FolderElem,
                          NameAttr, nameVal] )];
  
  [self dumpItemContents: [dirItem getContents]];
  
  [self appendString: [NSString stringWithFormat: @"</%@>\n", FolderElem]];
  
  [progressTracker processedFolder: dirItem];
}


- (void) appendFileElement: (FileItem *)fileItem {
  NSString  *nameVal = escapedXML([fileItem name], ATTRIBUTE_ESCAPE_CHARS);
  [self appendString: 
          ( ([fileItem fileItemFlags] != 0) 
            ? [NSString stringWithFormat:
                          @"<%@ %@=\"%@\" %@=\"%qu\" %@=\"%d\" />\n", 
                          FileElem,
                          NameAttr, nameVal, 
                          SizeAttr, [fileItem itemSize],
                          FlagsAttr, [fileItem fileItemFlags]]
            : [NSString stringWithFormat:
                          @"<%@ %@=\"%@\" %@=\"%qu\" />\n", 
                          FileElem,
                          NameAttr, nameVal, 
                          SizeAttr, [fileItem itemSize]] )];
}


- (void) dumpItemContents: (Item *)item {
  if (abort) {
    return;
  }
  
  if ([item isVirtual]) {
    [self dumpItemContents: [((CompoundItem *)item) getFirst]];
    [self dumpItemContents: [((CompoundItem *)item) getSecond]];
  }
  else {
    FileItem  *fileItem = (FileItem *)item;
    
    if ([fileItem isPhysical]) {
      // Only include actual files.

      if ([fileItem isDirectory]) {
        [self appendFolderElement: (DirectoryItem *)fileItem];
      }
      else {
        [self appendFileElement: fileItem];
      }
    }
  }
}


- (void) appendString: (NSString *)s {
  if (error != nil) {
    // Don't write anything when an error has occurred. 
    //
    // Note: Still keep writing if "only" the abort flag is set. This way, an
    // external "abort" of the write operation still results in valid XML.
    return;
  }

  NSData  *newData = [s dataUsingEncoding: NSUTF8StringEncoding];
  const void  *newDataBytes = [newData bytes];
  unsigned  numToAppend = [newData length];
  unsigned  newDataPos = 0;
  
  while (numToAppend > 0) {
    unsigned  numToCopy = ( (dataBufferPos + numToAppend <= BUFFER_SIZE)
                            ? numToAppend 
                            : BUFFER_SIZE - dataBufferPos );

    memcpy( dataBuffer + dataBufferPos, newDataBytes + newDataPos, numToCopy );
    dataBufferPos += numToCopy;
    newDataPos += numToCopy;
    numToAppend -= numToCopy;
    
    if (dataBufferPos == BUFFER_SIZE) {
      unsigned  numWritten = fwrite( dataBuffer, 1, BUFFER_SIZE, file );
      
      if (numWritten != BUFFER_SIZE) {
        NSLog(@"Failed to write entire buffer, %d bytes written", numWritten);
        
        error = [[ApplicationError alloc] initWithLocalizedDescription: 
                    WRITING_BUFFER_FAILED];
        abort = YES;
        
        return; // Do not attempt anymore writes to file.
      }
      
      dataBufferPos = 0;
    }
  }
}

@end // @implementation TreeWriter (PrivateMethods) 