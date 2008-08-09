#import "TreeReader.h"

#import "TreeConstants.h"

#import "TreeContext.h"
#import "DirectoryItem.h"
#import "PlainFileItem.h"
#import "CompoundItem.h"

#import "TreeBuilder.h"
#import "TreeBalancer.h"

#import "UniformTypeInventory.h"

NSString  *AttributeParseException = @"AttributeParseException";
NSString  *AttributeNameKey = @"name";


@interface TreeReader (PrivateMethods) 

- (BOOL) isAborted;
- (NSXMLParser *) parser;

@end


@interface ElementHandler : NSObject {
  NSString  *elementName;
  TreeReader  *reader;

  id  callback;
  SEL  successSelector;
}

- (id) initWithElement: (NSString *)elementName
         reader: (TreeReader *)reader
         callback: (id) callback
         onSuccess: (SEL) successSelector;


/* Generic callback method for when a child handler completes successfully.
 * Subclasses should define and use additional callback methods of their own 
 * for handling specific child elements and subsequently call this method for
 * the generic clean-up.
 *
 * Note: This method is used as the callback for "unrecognized" elements, so
 * care should be taken when overriding this method (there should be no need).
 */
- (void) handler: (ElementHandler *)handler 
           finishedParsingElement: (id) result;

/* Callback methods when child handler failed. The error callback cannot be
 * configured so this method will be always called.
 */
- (void) handler: (ElementHandler *)handler 
           failedParsingElement: (NSError *)parseError;


/* Called once to provide the handler with the attributes for the element.
 */
- (void) handleAttributes: (NSDictionary *)attribs;

/* Called when the start of a new child element is encountered.
 */
- (void) handleChildElement: (NSString *)elementName 
           attributes: (NSDictionary *)attribs;

/* Called when the end of the element represented by this handler is 
 * encountered.
 */
- (id) objectForElement;

/* Should be called when the handler encounters an error (i.e. so it should not
 * be called when the parser has signalled an error). It will abort the 
 * parsing.
 */
- (void) handlerError: (NSString *)details;

/* Should be called when the handler encounters an error when parsing the
 * attributes. It will indirectly invoke -handleError:.
 */
- (void) handlerAttributeParseError: (NSException *)ex;


- (NSString *) getStringAttributeValue: (NSString *)name 
                 from: (NSDictionary *)attribs defaultValue: (NSString *)defVal;
- (ITEM_SIZE) getItemSizeAttributeValue: (NSString *)name 
                 from: (NSDictionary *)attribs defaultValue: (NSString *)defVal;
- (NSDate *) getDateAttributeValue: (NSString *)name 
                 from: (NSDictionary *)attribs defaultValue: (NSString *)defVal;
- (int) getIntegerAttributeValue: (NSString *)name 
                 from: (NSDictionary *)attribs defaultValue: (NSString *)defVal;

@end


@interface ScanDumpElementHandler : ElementHandler {
  TreeContext  *tree;
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingScanInfoElement: (TreeContext *) tree;

@end // @interface ScanDumpElementHandler


@interface ScanInfoElementHandler : ElementHandler {
  TreeContext  *treeContext;
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingFolderElement: (DirectoryItem *) dirItem;

@end // @interface ScanInfoElementHandler


@interface FolderElementHandler : ElementHandler {
  DirectoryItem  *parentItem;
  DirectoryItem  *dirItem;
  NSMutableArray  *files;
  NSMutableArray  *dirs;
}

- (id) initWithElement: (NSString *)elementName
         reader: (TreeReader *)reader
         callback: (id) callback
         onSuccess: (SEL) successSelector
         parent: (DirectoryItem *)parent;

- (void) handler: (ElementHandler *)handler 
           finishedParsingFolderElement: (DirectoryItem *) dirItem;
- (void) handler: (ElementHandler *)handler 
           finishedParsingFileElement: (PlainFileItem *) fileItem;

@end // @interface FolderElementHandler


@interface FileElementHandler : ElementHandler {
  DirectoryItem  *parentItem;
  PlainFileItem  *fileItem;
}

- (id) initWithElement: (NSString *)elementName
         reader: (TreeReader *)reader
         callback: (id) callback
         onSuccess: (SEL) successSelector
         parent: (DirectoryItem *)parent;

@end // @interface FileElementHandler


/* Convenience function for creating an NSError object.
 *
 * Note: The returned object is not auto-released.
 */
NSError  *createNSError(NSString *details) {
  return
    [[NSError alloc] 
        initWithDomain: @"Application"
          code: -1 
          userInfo: [NSDictionary dictionaryWithObject: details
                                    forKey: NSLocalizedDescriptionKey]];
}


@implementation TreeReader

- (id) init {
  if (self = [super init]) {
    parser = nil;
    tree = nil;
    error = nil;
    abort = NO;
  }
  
  return self;
}

- (void) dealloc {
  NSAssert(parser == nil, @"parser should be nil.");
  NSAssert(tree == nil, @"tree should be nil.");
  
  [error release];
  
  [super dealloc];
}

- (TreeContext *) readTreeFromFile: (NSString *)path {
  NSAssert(parser == nil, @"Invalid state. Already reading?");

  // TODO: Using NSData loads the entire file into memory. It would be nice to
  // avoid this. This should be do-able, given that an event-streaming XML 
  // parser is used. Unfortunately, NSXMLParser does not (yet) support this.
  NSData  *data = [NSData dataWithContentsOfFile: path];
  if (data == nil) {
    return nil;
  }
  
  parser = [[NSXMLParser alloc] initWithData: data];
  [parser setDelegate: self];
  
  abort = NO;
  [error release];
  error = nil;
  
  [parser parse];
  
  [parser release];
  parser = nil;

  TreeContext  *retVal = (error!=nil || abort) ? nil : tree;
  [tree autorelease]; // Not releasing, as "retVal" should remain valid.
  tree = nil;
  
  return retVal;
}


- (void) abort {
  // TODO: Find out if NSXMLParser's -abortParsing is threadsafe. 
  // 
  // In the meantime, aborting ongoing parsing in a more roundabout way that 
  // is guaranteed to be threadsafe (it calls -abortParsing from the thread 
  // that also called -parse).
  
  abort = YES;
}


- (BOOL) aborted {
  return (error != nil) && abort;
}

- (NSError *) error {
  return error;
}

//----------------------------------------------------------------------------
// NSXMLParser delegate methods

- (void) parser: (NSXMLParser *)parserVal 
           didStartElement: (NSString *)elementName 
           namespaceURI: (NSString *)namespaceURI 
           qualifiedName: (NSString *)qName 
           attributes: (NSDictionary *)attribs {
  if (tree != nil) {
    // Already finished handling one GrandPerspectiveScanDump element.
    
    error = createNSError( 
              NSLocalizedString( @"Encountered more than one root element.",
                                 @"Parse error." ));
  }
  else if (! [elementName isEqualToString: @"GrandPerspectiveScanDump"]) {
    error = createNSError( 
              NSLocalizedString( @"Expected GrandPerspectiveScanDump element.",
                                 @"Parse error." ));
  }
  
  if (error != nil) {
    [parser abortParsing];
  }
  else {
    [[[ScanDumpElementHandler alloc] 
         initWithElement: elementName reader: self callback: self
           onSuccess: @selector(handler:finishedParsingScanDumpElement:)]
             handleAttributes: attribs];
  }
}

- (void) parser: (NSXMLParser *)parser 
           parseErrorOccurred: (NSError *)parseError {
  error = [parseError retain];
}


//----------------------------------------------------------------------------
// Handler callback methods

- (void) handler: (ElementHandler *)handler 
           failedParsingElement: (NSError *)parseError {
  [handler release];
  
  error = [parseError retain];
}

- (void) handler: (ElementHandler *)handler
           finishedParsingScanDumpElement: (TreeContext *)treeVal {
  [parser setDelegate: self];  
  tree = [treeVal retain];
  
  [handler release];
}

@end


@implementation TreeReader (PrivateMethods) 

- (BOOL) isAborted {
  return abort;
}

- (NSXMLParser *) parser {
  return parser;
}

@end // @implementation  TreeReader (PrivateMethods)


@implementation ElementHandler

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
  // NSLog(@"ElementHandler init: %@", elementNameVal);
  if (self = [super init]) {
    elementName = [elementNameVal retain];
    
    // Not retaining these, as these are not "owned"
    reader = readerVal;
    callback = callbackVal;

    successSelector = successSelectorVal;
    
    [[reader parser] setDelegate: self];
  }
  
  return self;
}

- (void) dealloc {
  [elementName release];

  [super dealloc];
}


//----------------------------------------------------------------------------
// NSXMLParser delegate methods (there should be no need to override these)

- (void) parser: (NSXMLParser *)parser 
           didStartElement: (NSString *)childElement 
           namespaceURI: (NSString *)namespaceURI 
           qualifiedName: (NSString *)qName 
           attributes: (NSDictionary *)attribs {
  if ([reader isAborted]) {
    [[reader parser] abortParsing];
  }
  else {
    [self handleChildElement: childElement attributes: attribs];
  }
}

- (void) parser: (NSXMLParser *)parser 
           didEndElement: (NSString *)elementNameVal
           namespaceURI: (NSString *)namespaceURI 
           qualifiedName: (NSString *)qName {
  NSAssert([elementNameVal isEqualToString: elementName], 
             @"Unexpected end of element");

  [callback performSelector: successSelector 
              withObject: self
              withObject: [self objectForElement]];
}

- (void) parser: (NSXMLParser *)parser 
           parseErrorOccurred: (NSError *)parseError {
  [callback handler: self failedParsingElement: parseError];
}


//----------------------------------------------------------------------------
// Handler callback methods

- (void) handler: (ElementHandler *)handler 
           failedParsingElement: (NSError *)parseError {
  [callback handler: self failedParsingElement: parseError];

  [handler release];  
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingElement: (id) result {
  [[reader parser] setDelegate: self];

  [handler release];
}


//----------------------------------------------------------------------------

/* Does nothing. To be overridden.
 */
- (void) handleAttributes: (NSDictionary *)attribs {
  // void
}

/* Called when the start of a new child element is encountered.
 *
 * Handles element by ignoring it. Override it to handle "known" elements, and
 * let this implementation handle all unrecognized ones.
 */
- (void) handleChildElement: (NSString *)childElement 
           attributes: (NSDictionary *)attribs {
  [[[ElementHandler alloc] 
       initWithElement: childElement reader: reader callback: self 
         onSuccess: @selector(handler:finishedParsingElement:) ]
           handleAttributes: attribs];
}

/* Called when the end of the element represented by this handler is 
 * encountered.
 *
 * Returns nil. Override it to return an object that represents the element.
 */
- (id) objectForElement {
  return nil;
}

- (void) handlerError: (NSString *)details {
  NSLog(@"Encountered error: %@", details);

  [[reader parser] abortParsing];

  NSError  *error = [createNSError(details) autorelease];
  
  [callback handler: self failedParsingElement: error];
}

- (void) handlerAttributeParseError: (NSException *)ex {
  NSString  *details = 
    [NSString stringWithFormat:
       NSLocalizedString(@"Error parsing %@ attribute: %@", @"Parse error"),
       [[ex userInfo] objectForKey: AttributeNameKey], [ex reason]];
       
  [self handlerError: details];
}


//----------------------------------------------------------------------------
// Attribute parsing helper methods

- (NSString *) getStringAttributeValue: (NSString *)name 
                 from: (NSDictionary *)attribs 
                 defaultValue: (NSString *)defVal { 

  NSString  *value = [attribs objectForKey: name];

  if (value != nil) {
    return value;
  }  
  if (defVal != nil) {
    return defVal;
  }

  NSString  *reason = 
    NSLocalizedString(@"Attribute not found.", @"Parse error");
  NSDictionary  *userInfo = 
    [NSDictionary dictionaryWithObject: name forKey: AttributeNameKey];
  NSException  *ex = 
    [[[NSException alloc] initWithName: AttributeParseException
                            reason: reason userInfo: userInfo] autorelease];
  [ex raise];
}

- (ITEM_SIZE) getItemSizeAttributeValue: (NSString *)name 
                from: (NSDictionary *)attribs 
                defaultValue: (NSString *)defVal {

  NSString  *stringValue = 
    [self getStringAttributeValue: name from: attribs defaultValue: defVal];

  NSScanner  *scanner = [NSScanner scannerWithString: stringValue];
  ITEM_SIZE  itemSizeValue;
  if (! ( [scanner scanLongLong: &itemSizeValue] 
          && [scanner isAtEnd]
          && itemSizeValue >= 0 ) ) {
    NSString  *reason = 
      NSLocalizedString(@"Expected unsigned integer value.", @"Parse error");
    NSDictionary  *userInfo = 
      [NSDictionary dictionaryWithObject: name forKey: AttributeNameKey];
    NSException  *ex = 
      [[[NSException alloc] initWithName: AttributeParseException
                              reason: reason userInfo: userInfo] autorelease];
    [ex raise];
  }
  
  return itemSizeValue;
}


- (NSDate *) getDateAttributeValue: (NSString *)name 
               from: (NSDictionary *)attribs
               defaultValue: (NSString *)defVal {

  NSString  *stringValue = 
    [self getStringAttributeValue: name from: attribs defaultValue: defVal];

  NSDate  *dateValue = [NSDate dateWithString: stringValue];
  // TODO: Check what happens if format is incorrect.

  return dateValue;
}


- (int) getIntegerAttributeValue: (NSString *)name 
          from: (NSDictionary *)attribs
          defaultValue: (NSString *)defVal {

  NSString  *stringValue = 
    [self getStringAttributeValue: name from: attribs defaultValue: defVal];

  NSScanner  *scanner = [NSScanner scannerWithString: stringValue];
  int  intValue;
  if (! ( [scanner scanInt: &intValue] 
          && [scanner isAtEnd] ) ) {
    NSString  *reason = 
      NSLocalizedString(@"Expected integer value.", @"Parse error");
    NSDictionary  *userInfo = 
      [NSDictionary dictionaryWithObject: name forKey: AttributeNameKey];
    NSException  *ex = 
      [[[NSException alloc] initWithName: AttributeParseException
                              reason: reason userInfo: userInfo] autorelease];
    [ex raise];
  }
  
  return intValue;
}

@end


@implementation ScanDumpElementHandler 

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
  if (self = [super initWithElement: elementNameVal reader: readerVal 
                      callback: callbackVal onSuccess: successSelectorVal]) {
    tree = nil;
  }
  
  return self;
}



- (void) handleAttributes: (NSDictionary *)attribs {
  // Not doing anything with "appVersion" and "formatVersion" attributes.
  // These can be ignored as they won't affect the parsing anyway (there
  // are no earlier formats, so these do not need to be handled especailly).
  
  [super handleAttributes: attribs];
}

  
- (void) handleChildElement: (NSString *)childElement 
           attributes: (NSDictionary *)attribs {
  if ([childElement isEqualToString: @"ScanInfo"]) {
    if (tree != nil) {
      [self handlerError: @"Encountered more than one ScanInfo element."];  
    }
    else {
      [[[ScanInfoElementHandler alloc] 
           initWithElement: childElement reader: reader callback: self 
             onSuccess: @selector(handler:finishedParsingScanInfoElement:) ]
               handleAttributes: attribs];
    }
  }
  else {
    [super handleChildElement: childElement attributes: attribs];
  }
}

- (id) objectForElement {
  return tree;
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingScanInfoElement: (TreeContext *) treeVal {
  NSAssert(tree == nil, @"Tree not nil.");
  
  tree = [treeVal retain];
  
  [self handler: handler finishedParsingElement: treeVal];
}
  
@end // @implementation ScanDumpElementHandler


@implementation ScanInfoElementHandler 

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
  if (self = [super initWithElement: elementNameVal reader: readerVal 
                      callback: callbackVal onSuccess: successSelectorVal]) {
    treeContext = nil;
  }
  
  return self;
}


- (void) handleAttributes: (NSDictionary *)attribs {
  NSAssert(treeContext == nil, @"treeContext not nil.");
  
  NS_DURING
    NSString  *volumePath = [self getStringAttributeValue: @"volumePath" 
                                    from: attribs defaultValue: nil];
    ITEM_SIZE  volumeSize = [self getItemSizeAttributeValue: @"volumeSize" 
                                    from: attribs defaultValue: nil];
    ITEM_SIZE  freeSpace = [self getItemSizeAttributeValue: @"freeSpace" 
                                   from: attribs defaultValue: @"0"];
    NSDate  *scanTime = [self getDateAttributeValue: @"scanTime" 
                                from: attribs defaultValue: nil];
    NSString  *sizeMeasure = [self getStringAttributeValue: @"fileSizeMeasure" 
                                     from: attribs defaultValue: nil];

    if (! ( [sizeMeasure isEqualToString: LogicalFileSize] ||
            [sizeMeasure isEqualToString: PhysicalFileSize] ) ) {
      NSString  *reason = 
        NSLocalizedString(@"Unrecognized value.", @"Parse error");
      NSDictionary  *userInfo = 
        [NSDictionary dictionaryWithObject: @"fileSizeMeasure" 
                        forKey: AttributeNameKey];
      NSException  *ex = 
        [[[NSException alloc] initWithName: AttributeParseException
                                reason: reason userInfo: userInfo] autorelease];
      [ex raise];
    }
  
    treeContext = [[TreeContext alloc]  
                      initWithVolumePath: volumePath
                      fileSizeMeasure: sizeMeasure
                      volumeSize: volumeSize 
                      freeSpace: freeSpace
                      filter: nil
                      scanTime: scanTime];
    // TODO: also parse freeSpace (also need to write it).
  NS_HANDLER
    if ([[localException name] isEqualToString: AttributeParseException]) {
      [self handlerAttributeParseError: localException];
    }
  NS_ENDHANDLER
}
  
- (void) handleChildElement: (NSString *)childElement 
           attributes: (NSDictionary *)attribs {
  if ([childElement isEqualToString: @"Folder"]) {
    if ([[treeContext scanTree] getContents] != nil) {
      [self handlerError: @"Encountered more than one root Folder element."];  
    }
    else {
      [[[FolderElementHandler alloc] 
           initWithElement: childElement reader: reader callback: self 
             onSuccess: @selector(handler:finishedParsingFolderElement:) 
             parent: [treeContext scanTreeParent]]
               handleAttributes: attribs];
    }
  }
  else {
    [super handleChildElement: childElement attributes: attribs];
  }
}

- (id) objectForElement {
  return treeContext;
}



- (void) handler: (ElementHandler *)handler 
           finishedParsingFolderElement: (DirectoryItem *) dirItem {
  [treeContext setScanTree: dirItem];
  
  [self handler: handler finishedParsingElement: dirItem];
}
  
@end // @implementation ScanInfoElementHandler 


@implementation FolderElementHandler 

// Overrides designated initialiser.
- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
  NSAssert(NO, @"Invoke with parent argument.");
}

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal
         parent: (DirectoryItem *)parentVal {
  if (self = [super initWithElement: elementNameVal reader: readerVal 
                      callback: callbackVal onSuccess: successSelectorVal]) {
    parentItem = [parentVal retain];

    files = [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY];
    dirs = [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY];
  }
  
  return self;
}

- (void) dealloc {
  [parentItem release];
  [dirItem release];
  
  [files release];
  [dirs release];
  
  [super dealloc];
}


- (void) handleAttributes: (NSDictionary *)attribs {
  NS_DURING
    NSString  *name = [self getStringAttributeValue: @"name" 
                              from: attribs defaultValue: nil];
    int  flags = [self getIntegerAttributeValue: @"flags"
                         from: attribs defaultValue: @"0"];

    dirItem = 
      [[DirectoryItem alloc]
          initWithName: name parent: parentItem flags: flags];
  NS_HANDLER
    if ([[localException name] isEqualToString: AttributeParseException]) {
      [self handlerAttributeParseError: localException];
    }
  NS_ENDHANDLER    
}

- (void) handleChildElement: (NSString *)childElement 
           attributes: (NSDictionary *)attribs {
  if ([childElement isEqualToString: @"Folder"]) {
    [[[FolderElementHandler alloc] 
         initWithElement: childElement reader: reader callback: self 
           onSuccess: @selector(handler:finishedParsingFolderElement:) 
           parent: dirItem]
             handleAttributes: attribs];
  }
  else if ([childElement isEqualToString: @"File"]) {
    [[[FileElementHandler alloc] 
         initWithElement: childElement reader: reader callback: self 
           onSuccess: @selector(handler:finishedParsingFileElement:) 
           parent: dirItem]
             handleAttributes: attribs];
  }
  else {
    [super handleChildElement: childElement attributes: attribs];
  }
}

- (id) objectForElement {
  TreeBalancer  *treeBalancer = [[TreeBalancer alloc] init];

  [dirItem setDirectoryContents: 
    [CompoundItem 
       compoundItemWithFirst: [treeBalancer createTreeForItems: files] 
                      second: [treeBalancer createTreeForItems: dirs]]];

  [treeBalancer release];
  
  return dirItem;
}


- (void) handler: (ElementHandler *)handler 
           finishedParsingFolderElement: (DirectoryItem *) childItem {
  [dirs addObject: childItem];
  
  [self handler: handler finishedParsingElement: childItem];
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingFileElement: (PlainFileItem *) childItem {
  [files addObject: childItem];
  
  [self handler: handler finishedParsingElement: childItem];
}

@end // @implementationFolderElementHandler 


@implementation FileElementHandler 

// Overrides designated initialiser.
- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
  NSAssert(NO, @"Invoke with parent argument.");
}

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal
         parent: (DirectoryItem *)parentVal {
  if (self = [super initWithElement: elementNameVal reader: readerVal 
                      callback: callbackVal onSuccess: successSelectorVal]) {
    parentItem = [parentVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [parentItem release];
  [fileItem release];
  
  [super dealloc];
}


- (void) handleAttributes: (NSDictionary *)attribs {
  NS_DURING
    NSString  *name = [self getStringAttributeValue: @"name" 
                              from: attribs defaultValue: nil];
    int  flags = [self getIntegerAttributeValue: @"flags"
                         from: attribs defaultValue: @"0"];
    ITEM_SIZE  size = [self getItemSizeAttributeValue: @"size" 
                              from: attribs defaultValue: nil];
    
    UniformTypeInventory  *typeInventory = 
      [UniformTypeInventory defaultUniformTypeInventory];
    UniformType  *fileType = 
      [typeInventory uniformTypeForExtension: [name pathExtension]];

    fileItem = 
      [[PlainFileItem alloc]
          initWithName: name parent: parentItem size: size
            type: fileType flags: flags];
  NS_HANDLER
    if ([[localException name] isEqualToString: AttributeParseException]) {
      [self handlerAttributeParseError: localException];
    }
  NS_ENDHANDLER    
}

- (id) objectForElement {
  return fileItem;
}

@end // @implementation FileElementHandler 