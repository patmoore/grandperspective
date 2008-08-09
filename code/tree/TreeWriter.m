#import "TreeWriter.h"

#import "DirectoryItem.h"
#import "CompoundItem.h"

#import "TreeContext.h"


#define  BUFFER_SIZE  4096

NSString  *TreeWriterFormatVersion = @"1";


/* Escapes the string so that it is a valid XML attribute value. This means
 * that the '&', '<' and '"' characters are all be replaced by their
 * encoded representations, respectively "&amp;", "&lt;" and "&quot;".
 */
NSString *escapedAttributeValue(NSString *s) {
  // Lazily construct buffer. Only use it when needed.
  NSMutableString  *buf = nil;
  
  int  i;
  int  numCharsInVal = [s length];
  int  numCharsInBuf = 0;
  
  for (i = 0; i < numCharsInVal; i++) {
    unichar  c = [s characterAtIndex: i];
    NSString  *r = nil;
    if (c == '&') {
      r = @"&amp;";
    }
    else if (c == '<') {
      r = @"&lt;";
    }
    else if (c== '"') {
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

- (void) appendScanDumpElement: (TreeContext *)tree;
- (void) appendScanInfoElement: (TreeContext *)tree;
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
    error = NO;
  }
  return self;
}

- (void) dealloc {
  free(dataBuffer);

  [super dealloc];
}


- (BOOL) writeTree: (TreeContext *)tree toFile: (NSString *)filename {
  NSAssert(file == NULL, @"File not NULL");

  NSLog(@"Start dump");
  
  file = fopen( [filename cString], "w");
  if (file == NULL) {
    return NO;
  }

  dataBufferPos = 0;

  [self appendString: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
  [self appendScanDumpElement: tree];
  
  if (!error && dataBufferPos > 0) {
    // Write remaining characters in buffer
    unsigned  numWritten = fwrite( dataBuffer, 1, dataBufferPos, file );
    
    if (numWritten != dataBufferPos) {
      NSLog(@"Failed to write last data: %d bytes written out of %d.", 
                numWritten, dataBufferPos);
      error = YES;
    }
  }
  
  fclose(file);
  file = NULL;
  
  NSLog(@"Dump completed");
  
  return !(abort || error);
}

- (void) abort {
  abort = YES;
}

@end


@implementation TreeWriter (PrivateMethods) 

- (void) appendScanDumpElement: (TreeContext *)tree {
  NSString  *appVersion =
    [[[NSBundle mainBundle] infoDictionary] objectForKey: 
                                              @"CFBundleVersion"];

  NSMutableString  *buf = [NSMutableString stringWithCapacity: 64];
  [buf appendString: @"<GrandPerspectiveScanDump"];
  [buf appendFormat: @" appVersion=\"%@\"", appVersion];
  [buf appendFormat: @" formatVersion=\"%@\"", TreeWriterFormatVersion];
  [buf appendString: @">\n"];  
  [self appendString: buf];
  
  [self appendScanInfoElement: tree];
  
  [self appendString: @"</GrandPerspectiveScanDump>\n"];
}


- (void) appendScanInfoElement: (TreeContext *)tree {
  NSMutableString  *buf = [NSMutableString stringWithCapacity: 256];
  [buf appendString: @"<ScanInfo"];
  [buf appendFormat: @" volumePath=\"%@\"", 
                       escapedAttributeValue([[tree volumeTree] name])];
  [buf appendFormat: @" volumeSize=\"%qu\"", [tree volumeSize]];
  [buf appendFormat: @" freeSpace=\"%qu\"", ( [tree freeSpace] + 
                                              [tree freedSpace] )];
  [buf appendFormat: @" scanTime=\"%@\"", [tree scanTime]];
  [buf appendFormat: @" fileSizeMeasure=\"%@\"", [tree fileSizeMeasure]];
  [buf appendString: @">\n"];
  [self appendString: buf];
  
  [tree obtainReadLock];
  [self appendFolderElement: [tree scanTree]];
  [tree releaseReadLock];
  
  [self appendString: @"</ScanInfo>\n"];
}


- (void) appendFolderElement: (DirectoryItem *)dirItem {
  NSString  *nameVal = escapedAttributeValue([dirItem name]);
  [self appendString: 
          ( ([dirItem fileItemFlags] != 0) 
            ? [NSString stringWithFormat:
                          @"<Folder name=\"%@\" flags=\"%d\">\n", 
                          nameVal, [dirItem fileItemFlags]]
            : [NSString stringWithFormat:
                          @"<Folder name=\"%@\">\n", 
                         nameVal] )];
  
  [self dumpItemContents: [dirItem getContents]];
  
  [self appendString: @"</Folder>\n"];
}


- (void) appendFileElement: (FileItem *)fileItem {
  NSString  *nameVal = escapedAttributeValue([fileItem name]);
  [self appendString: 
          ( ([fileItem fileItemFlags] != 0) 
            ? [NSString stringWithFormat:
                          @"<File name=\"%@\" size=\"%qu\" flags=\"%d\" />\n", 
                         nameVal, [fileItem itemSize],
                         [fileItem fileItemFlags]]
            : [NSString stringWithFormat:
                          @"<File name=\"%@\" size=\"%qu\" />\n", 
                         nameVal, [fileItem itemSize]] )];
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
    
    if ([fileItem isSpecial]) {
      // Skip all special items
    }
    else {
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
  if (error) {
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
        error = YES;
        abort = YES;
        
        return; // Do not attempt anymore writes to file.
      }
      
      dataBufferPos = 0;
    }
  }
}

@end // @implementation TreeWriter (PrivateMethods) 