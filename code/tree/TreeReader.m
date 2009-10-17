#import "TreeReader.h"

#import "TreeConstants.h"

#import "TreeContext.h"
#import "AnnotatedTreeContext.h"
#import "DirectoryItem.h"
#import "PlainFileItem.h"
#import "CompoundItem.h"

#import "Filter.h"
#import "FilterSet.h"
#import "FilterTestRef.h"
#import "FilterTestRepository.h"

#import "TreeBuilder.h"
#import "TreeBalancer.h"
#import "TreeWriter.h"

#import "AutoreleaseProgressTracker.h"

#import "UniformTypeInventory.h"
#import "ApplicationError.h"
#import "MutableArrayPool.h"


NSString  *AttributeNameKey = @"name";

// Localized error messages
#define PARSE_ERROR_MSG \
  NSLocalizedString(@"Parse error (line %d): %@", @"Parse error")
#define ATTR_PARSE_ERROR_MSG \
  NSLocalizedString(@"Error parsing \"%@\" attribute: %@", @"Parse error")

#define EXPECTED_ELEM_MSG \
  NSLocalizedString(@"Expected %@ element.", @"Parse error")

#define MULTIPLE_ELEM_MSG \
  NSLocalizedString(@"Encountered multiple %@ elements.", @"Parse error")
#define MULTIPLE_ROOT_ELEM_MSG \
  NSLocalizedString(@"Encountered more than one root element.", @"Parse error")
#define MULTIPLE_ROOT_FOLDER_MSG \
  NSLocalizedString(@"Encountered more than one root folder.", @"Parse error")
#define FILTER_AFTER_FOLDER_MSG \
  NSLocalizedString(@"Encountered filter after folder.", @"Parse error")

#define PARSING_ABORTED_MSG \
  NSLocalizedString(@"Parsing aborted", @"Parse error")

#define ATTR_NOT_FOUND_MSG \
  NSLocalizedString(@"Attribute not found.", @"Parse error")

#define EXPECTED_UINT_VALUE_MSG \
  NSLocalizedString(@"Expected unsigned integer value.", @"Parse error")
#define EXPECTED_INT_VALUE_MSG \
  NSLocalizedString(@"Expected integer value.", @"Parse error")
#define EXPECTED_BOOL_VALUE_MSG \
  NSLocalizedString(@"Expected boolean value.", @"Parse error")
#define EXPECTED_DATE_VALUE_MSG \
  NSLocalizedString(@"Expected date value.", @"Parse error")

#define UNRECOGNIZED_VALUE_MSG \
  NSLocalizedString(@"Unrecognized value.", @"Parse error")


@interface TreeReader (PrivateMethods) 

- (BOOL) isAborted;
- (NSXMLParser *)parser;
- (ProgressTracker *)progressTracker;
- (TreeBalancer *)treeBalancer;
- (ObjectPool *)dirsArrayPool;
- (ObjectPool *)filesArrayPool;

- (FilterTestRepository *)filterTestRepository;
- (NSMutableArray *)mutableUnboundFilterTests;

- (void) setParseError:(NSError *)error;

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
                 from: (NSDictionary *)attribs;
- (NSString *) getStringAttributeValue: (NSString *)name 
                 from: (NSDictionary *)attribs defaultValue: (NSString *)defVal;

- (ITEM_SIZE) getItemSizeAttributeValue: (NSString *)name 
                from: (NSDictionary *)attribs;
- (ITEM_SIZE) getItemSizeAttributeValue: (NSString *)name 
                from: (NSDictionary *)attribs defaultValue: (ITEM_SIZE) defVal;

- (NSDate *) getDateAttributeValue: (NSString *)name 
               from: (NSDictionary *)attribs;
- (NSDate *) getDateAttributeValue: (NSString *)name 
               from: (NSDictionary *)attribs defaultValue: (NSDate *)defVal;

- (int) getIntegerAttributeValue: (NSString *)name 
          from: (NSDictionary *)attribs;
- (int) getIntegerAttributeValue: (NSString *)name 
          from: (NSDictionary *)attribs defaultValue: (int) defVal;

- (BOOL) getBooleanAttributeValue: (NSString *)name 
           from: (NSDictionary *)attribs;
- (BOOL) getBooleanAttributeValue: (NSString *)name 
           from: (NSDictionary *)attribs defaultValue: (BOOL) defVal;
                 
@end // @interface ElementHandler


@interface ElementHandler (PrivateMethods) 

- (ITEM_SIZE) parseItemSizeAttribute: (NSString *)name value: (NSString *)value;
- (NSDate *) parseDateAttribute: (NSString *)name value: (NSString *)value;
- (int) parseIntegerAttribute: (NSString *)name value: (NSString *)value;
- (BOOL) parseBooleanAttribute: (NSString *)name value: (NSString *)value;

@end // @interface ElementHandler (PrivateMethods) 


@interface ScanDumpElementHandler : ElementHandler {
  AnnotatedTreeContext  *annotatedTree;
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingScanInfoElement: (AnnotatedTreeContext *) tree;

@end // @interface ScanDumpElementHandler


@interface ScanInfoElementHandler : ElementHandler {
  NSString  *comments;
  TreeContext  *tree;
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingCommentsElement: (NSString *) comments;
- (void) handler: (ElementHandler *)handler
           finishedParsingFilterSetElement: (FilterSet *)filterSet;
- (void) handler: (ElementHandler *)handler 
           finishedParsingFolderElement: (DirectoryItem *) dirItem;

@end // @interface ScanInfoElementHandler


@interface ScanCommentsElementHandler : ElementHandler {
  NSMutableString  *comments;
}
 
@end // @interface ScanCommentsElementHandler


@interface FilterSetElementHandler : ElementHandler {
  FilterSet  *filterSet;
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingFilterElement: (Filter *) filter;
 
@end // @interface FilterSetElementHandler


@interface FilterElementHandler : ElementHandler {
  NSMutableArray  *filterTests;
  NSString  *name;
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingFilterTestElement: (FilterTestRef *) filterTest;

@end // @interface FilterElementHandler


@interface FilterTestElementHandler : ElementHandler {
  FilterTestRef  *filterTest;
}

@end // @interface FilterTestElementHandler


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


@interface AttributeParseException : NSException {
}

- (id) initWithAttributeName: (NSString *)attribName 
         reason: (NSString *)reason;
         
+ (id) exceptionWithAttributeName: (NSString *)attribName 
         reason: (NSString *)reason;

@end // @interface AttributeParseException


@implementation TreeReader

- (id) init {
  return [self initWithFilterTestRepository:
                 [FilterTestRepository defaultFilterTestRepository]];
}

- (id) initWithFilterTestRepository:(FilterTestRepository *)repository {
  if (self = [super init]) {
    testRepository = [repository retain];
  
    parser = nil;
    tree = nil;
    error = nil;
    abort = NO;
    
    unboundTests = [[NSMutableArray alloc] initWithCapacity: 8];
    
    // Either ProgressTracker can be used, or AutoreleaseProgressTracker. Using
    // the latter means that temporary objects using autorelease will be 
    // released while a tree is being read, thus reducing the total amount of
    // memory needed. However, execution is slower (by approximately 10%),
    // presumably because it fragments the memory, which slows allocation of
    // new objects. 
    progressTracker = [[ProgressTracker alloc] init];

    treeBalancer = [[TreeBalancer alloc] init];

    dirsArrayPool = [[MutableArrayPool alloc] 
                        initWithCapacity: 16 
                        initialArrayCapacity: INITIAL_DIRS_CAPACITY * 4];
    filesArrayPool = [[MutableArrayPool alloc] 
                        initWithCapacity: 16 
                        initialArrayCapacity: INITIAL_FILES_CAPACITY * 4];
  }
  
  return self;
}

- (void) dealloc {
  NSAssert(parser == nil, @"parser should be nil.");
  
  [testRepository release];

  [tree release]; 
  [error release];
  [unboundTests release];
  
  [progressTracker release];
  [treeBalancer release];
  [dirsArrayPool release];
  [filesArrayPool release];
  
  [super dealloc];
}

- (AnnotatedTreeContext *)readTreeFromFile:(NSString *)path {
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
  
  [tree release];
  tree = nil;
  
  abort = NO;
  [error release];
  error = nil;
  
  [unboundTests removeAllObjects];
  
  [progressTracker startingTask];
  
  [parser parse];
  
  [progressTracker finishedTask];
  
  [parser release];
  parser = nil;

  return (error!=nil || abort) ? nil : tree;
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

- (AnnotatedTreeContext *)annotatedTreeContext {
  return tree;
}

- (NSError *)error {
  return error;
}

- (NSArray *)unboundFilterTests {
  // Return a copy
  return [NSArray arrayWithArray: unboundTests];
}

- (NSDictionary *)progressInfo {
  return [progressTracker progressInfo];
}


//----------------------------------------------------------------------------
// NSXMLParser delegate methods

- (void) parser:(NSXMLParser *)parserVal 
           didStartElement:(NSString *)elementName 
           namespaceURI:(NSString *)namespaceURI 
           qualifiedName:(NSString *)qName 
           attributes:(NSDictionary *)attribs {
  NSError  *parseError = nil;
  if (tree != nil) {
    parseError = [ApplicationError errorWithLocalizedDescription:
                                     MULTIPLE_ROOT_ELEM_MSG];
  }
  else if (! [elementName isEqualToString: ScanDumpElem]) {
    parseError =
      [ApplicationError errorWithLocalizedDescription:
         [NSString stringWithFormat: EXPECTED_ELEM_MSG, ScanDumpElem]];
  }
  
  if (parseError != nil) {
    [self setParseError: parseError];
    [parser abortParsing];
  }
  else {
    [[[ScanDumpElementHandler alloc] 
         initWithElement: elementName reader: self callback: self
           onSuccess: @selector(handler:finishedParsingScanDumpElement:)]
             handleAttributes: attribs];
  }
}

- (void) parser:(NSXMLParser *)parser 
           parseErrorOccurred:(NSError *)parseError {
  [self setParseError: parseError];
}


//----------------------------------------------------------------------------
// Handler callback methods

- (void) handler:(ElementHandler *)handler 
           failedParsingElement:(NSError *)parseError {
  [parser setDelegate: self];
  
  [self setParseError: parseError];
  
  [handler release];
  
  [parser abortParsing];
}

- (void) handler:(ElementHandler *)handler
           finishedParsingScanDumpElement:(AnnotatedTreeContext *)treeVal {
  [parser setDelegate: self];
  
  tree = [treeVal retain];
    
  [handler release];
}

@end // @implementation TreeReader


@implementation TreeReader (PrivateMethods) 

- (BOOL) isAborted {
  return abort;
}

- (NSXMLParser *)parser {
  return parser;
}

- (ProgressTracker *)progressTracker {
  return progressTracker;
}

- (TreeBalancer *)treeBalancer {
  return treeBalancer;
}

- (ObjectPool *)dirsArrayPool {
  return dirsArrayPool;
}

- (ObjectPool *)filesArrayPool {
  return filesArrayPool;
}

- (FilterTestRepository *)filterTestRepository {
  return testRepository;
}

- (NSMutableArray *)mutableUnboundFilterTests {
  return unboundTests;
}


- (void) setParseError:(NSError *)parseError {
  if ( error == nil // There is no error yet
       && !abort    // ... and parsing has not been aborted (this also 
                    // triggers an error, which should be ignored).
     ) {
    error = 
      [[ApplicationError alloc] initWithLocalizedDescription:
          [NSString stringWithFormat: PARSE_ERROR_MSG, 
                      [parser lineNumber],
                      [parseError localizedDescription]]];
  }
}

@end // @implementation  TreeReader (PrivateMethods)


@implementation ElementHandler

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
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
    NSError  *error = 
      [ApplicationError errorWithLocalizedDescription: PARSING_ABORTED_MSG];
    [callback handler: self failedParsingElement: error];
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
  [[reader parser] setDelegate: self];
  
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
  NSError  *error = [ApplicationError errorWithLocalizedDescription: details];
  [callback handler: self failedParsingElement: error];
}

- (void) handlerAttributeParseError: (NSException *)ex {
  NSString  *details = 
    [NSString stringWithFormat: ATTR_PARSE_ERROR_MSG,
                [[ex userInfo] objectForKey: AttributeNameKey], [ex reason]];
       
  [self handlerError: details];
}


//----------------------------------------------------------------------------
// Attribute parsing helper methods

- (NSString *) getStringAttributeValue: (NSString *)name 
                 from: (NSDictionary *)attribs { 
  NSString  *value = [attribs objectForKey: name];

  if (value != nil) {
    return value;
  } 

  NSException  *ex = 
    [[[AttributeParseException alloc]
         initWithAttributeName: name reason: ATTR_NOT_FOUND_MSG] autorelease];
  @throw ex;
}

- (NSString *) getStringAttributeValue: (NSString *)name 
                 from: (NSDictionary *)attribs 
                 defaultValue: (NSString *)defVal { 
  NSString  *value = [attribs objectForKey: name];

  return (value != nil) ? value : defVal;
}


- (ITEM_SIZE) getItemSizeAttributeValue: (NSString *)name 
                from: (NSDictionary *)attribs {
  return [self parseItemSizeAttribute: name
                 value: [self getStringAttributeValue: name from: attribs]];
}

- (ITEM_SIZE) getItemSizeAttributeValue: (NSString *)name 
                from: (NSDictionary *)attribs defaultValue: (ITEM_SIZE) defVal {
  NSString  *stringValue = [attribs objectForKey: name];

  return ( (stringValue != nil) 
           ? [self parseItemSizeAttribute: name value: stringValue] : defVal );
}


- (NSDate *) getDateAttributeValue: (NSString *)name 
               from: (NSDictionary *)attribs {
  return [self parseDateAttribute: name
                 value: [self getStringAttributeValue: name from: attribs]];
}

- (NSDate *) getDateAttributeValue: (NSString *)name 
               from: (NSDictionary *)attribs
               defaultValue: (NSDate *)defVal {
  NSString  *stringValue = [attribs objectForKey: name];

  return ( (stringValue != nil) 
           ? [self parseDateAttribute: name value: stringValue] : defVal );
}


- (int) getIntegerAttributeValue: (NSString *)name 
          from: (NSDictionary *)attribs {
  return [self parseIntegerAttribute: name
                 value: [self getStringAttributeValue: name from: attribs]];
}

- (int) getIntegerAttributeValue: (NSString *)name 
          from: (NSDictionary *)attribs
          defaultValue: (int) defVal {
  NSString  *stringValue = [attribs objectForKey: name];

  return ( (stringValue != nil) 
           ? [self parseIntegerAttribute: name value: stringValue] : defVal );
}

- (BOOL) getBooleanAttributeValue: (NSString *)name 
           from: (NSDictionary *)attribs {
  return [self parseBooleanAttribute: name 
                 value: [self getStringAttributeValue: name from: attribs]];
}

- (BOOL) getBooleanAttributeValue: (NSString *)name 
           from: (NSDictionary *)attribs defaultValue: (BOOL) defVal { 
  NSString  *stringValue = [attribs objectForKey: name];
  
  return ( (stringValue != nil)
           ? [self parseBooleanAttribute: name value: stringValue] : defVal );
}

@end // @implementation ElementHandler


@implementation ElementHandler (PrivateMethods) 

- (ITEM_SIZE) parseItemSizeAttribute: (NSString *)name 
                value: (NSString *)stringValue {
  // Using own parsing code instead of NSScanner's scanLongLong for two 
  // reasons:
  // 1) NSScanner cannot handle unsigned long long values
  // 2) This is faster (partly because there's no need to allocate and release
  //    memory).

  ITEM_SIZE  size = 0;
  int  i = 0;
  int  len = [stringValue length];
  while (i < len) {
    unichar  ch = [stringValue characterAtIndex: i++];
    
    if (ch < '0' || ch > '9') {
      NSException  *ex = [AttributeParseException 
                            exceptionWithAttributeName: name 
                            reason: EXPECTED_UINT_VALUE_MSG];
      @throw ex;
    }
    
    size = size * 10 + (ch - '0');
  }
  
  return size;
}

- (NSDate *) parseDateAttribute: (NSString *)name 
               value: (NSString *)stringValue {
  NSDate  *dateValue = [NSDate dateWithString: stringValue];
  
  if (dateValue == nil) {
    NSException  *ex = [AttributeParseException 
                          exceptionWithAttributeName: name 
                          reason: EXPECTED_DATE_VALUE_MSG];
    @throw ex;
  }

  return dateValue;
}

- (int) parseIntegerAttribute: (NSString *)name 
          value: (NSString *)stringValue {
  // Note: Explicitly releasing scanner to minimise use of autorelease pool.
  NSScanner  *scanner = [[NSScanner alloc] initWithString: stringValue];
  int  intValue;
  BOOL  ok  = ( [scanner scanInt: &intValue] && [scanner isAtEnd] );
  [scanner release];
     
  if (! ok) {
    NSException  *ex = [AttributeParseException 
                          exceptionWithAttributeName: name 
                          reason: EXPECTED_INT_VALUE_MSG];
    @throw ex;
  }
  
  return intValue;
}

- (BOOL) parseBooleanAttribute: (NSString *)name value: (NSString *)value {
  NSString  *lcValue = [value lowercaseString];
  
  if ([lcValue isEqualToString: @"true"] ||
      [lcValue isEqualToString: @"1"]) {
    return YES;
  }
  else if  ([lcValue isEqualToString: @"false"] ||
            [lcValue isEqualToString: @"0"]) {
    return NO;
  }
  
  NSException  *ex = [AttributeParseException 
                        exceptionWithAttributeName: name 
                        reason: EXPECTED_BOOL_VALUE_MSG];
  @throw ex;
}

@end // @implementation ElementHandler (PrivateMethods) 


@implementation ScanDumpElementHandler 

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
  if (self = [super initWithElement: elementNameVal reader: readerVal 
                      callback: callbackVal onSuccess: successSelectorVal]) {
    annotatedTree = nil;
  }
  
  return self;
}

- (void) dealloc {
  [annotatedTree release];
  
  [super dealloc];
}


- (void) handleAttributes: (NSDictionary *)attribs {
  // Not doing anything with "appVersion" and "formatVersion" attributes.
  // These can be ignored as they won't affect the parsing anyway (there
  // are no earlier formats, so these do not need to be handled especailly).
  
  [super handleAttributes: attribs];
}

- (void) handleChildElement: (NSString *)childElement 
           attributes: (NSDictionary *)attribs {
  if ([childElement isEqualToString: ScanInfoElem]) {
    if (annotatedTree != nil) {
      [self handlerError: 
        [NSString stringWithFormat: MULTIPLE_ELEM_MSG, ScanInfoElem]];
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
  return annotatedTree;
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingScanInfoElement: (AnnotatedTreeContext *) treeVal {
  NSAssert(annotatedTree == nil, @"Tree not nil.");
  
  annotatedTree = [treeVal retain];
  
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
    comments = nil;
    tree = nil;
  }
  
  return self;
}

- (void) dealloc {
  [comments release];
  [tree release];
  
  [super dealloc];
}


- (void) handleAttributes: (NSDictionary *)attribs {
  NSAssert(tree == nil, @"tree not nil.");
  
  @try {
    NSString  *volumePath = 
      [self getStringAttributeValue: VolumePathAttr from: attribs];
    ITEM_SIZE  volumeSize = 
      [self getItemSizeAttributeValue: VolumeSizeAttr from: attribs];
    ITEM_SIZE  freeSpace = 
      [self getItemSizeAttributeValue: FreeSpaceAttr from: attribs];
    NSDate  *scanTime = 
      [self getDateAttributeValue: ScanTimeAttr from: attribs];
    NSString  *sizeMeasure = 
      [self getStringAttributeValue: FileSizeMeasureAttr from: attribs];

    if (! ( [sizeMeasure isEqualToString: LogicalFileSize] ||
            [sizeMeasure isEqualToString: PhysicalFileSize] ) ) {
      NSException  *ex = 
        [AttributeParseException 
           exceptionWithAttributeName: FileSizeMeasureAttr 
           reason: UNRECOGNIZED_VALUE_MSG];
      @throw ex;
    }
  
    tree = [[TreeContext alloc] 
               initWithVolumePath: volumePath
               fileSizeMeasure: sizeMeasure
               volumeSize: volumeSize 
               freeSpace: freeSpace
               filterSet: nil
               scanTime: scanTime];
  }
  @catch (AttributeParseException *ex) {
    [self handlerAttributeParseError: ex];
  }
}
  
- (void) handleChildElement: (NSString *)childElement 
           attributes: (NSDictionary *)attribs {
  if ([childElement isEqualToString: ScanCommentsElem]) {
    if (comments != nil) {
      [self handlerError:
        [NSString stringWithFormat: MULTIPLE_ELEM_MSG, ScanCommentsElem]]; 
    }
    else {
      [[[ScanCommentsElementHandler alloc]
           initWithElement: childElement reader: reader callback: self
           onSuccess: @selector(handler:finishedParsingCommentsElement:)]
             handleAttributes: attribs];
    }
  }
  else if ([childElement isEqualToString: FilterSetElem]) {
    if ([tree scanTree] != nil) {
      [self handlerError: FILTER_AFTER_FOLDER_MSG];
    }
    else if ([[tree filterSet] numFilters] > 0) {
      [self handlerError:
        [NSString stringWithFormat: MULTIPLE_ELEM_MSG, FilterSetElem]];
    }
    else {
      [[[FilterSetElementHandler alloc]
           initWithElement: childElement reader: reader callback: self
           onSuccess: @selector(handler:finishedParsingFilterSetElement:)]
             handleAttributes: attribs];
    }
  }
  else if ([childElement isEqualToString: FolderElem]) {
    if ([[tree scanTree] getContents] != nil) {
      [self handlerError: MULTIPLE_ROOT_FOLDER_MSG];
    }
    else {
      [[[FolderElementHandler alloc] 
           initWithElement: childElement reader: reader callback: self 
             onSuccess: @selector(handler:finishedParsingFolderElement:) 
             parent: [tree scanTreeParent]]
               handleAttributes: attribs];
    }
  }
  else {
    [super handleChildElement: childElement attributes: attribs];
  }
}

- (id) objectForElement {
  return [AnnotatedTreeContext annotatedTreeContext: tree comments: comments];
}


- (void) handler: (ElementHandler *)handler 
           finishedParsingCommentsElement: (NSString *) commentsVal {
  comments = [commentsVal retain];
  
  [self handler: handler finishedParsingElement: comments];
}

- (void) handler: (ElementHandler *)handler
           finishedParsingFilterSetElement: (FilterSet *)filterSet {
  TreeContext  *oldTree = tree;

  // Replace tree by new one that also contains the given filter set. 
  tree = [[TreeContext alloc] 
             initWithVolumePath: [[oldTree volumeTree] name]
             fileSizeMeasure: [oldTree fileSizeMeasure]
             volumeSize: [oldTree volumeSize] 
             freeSpace: [oldTree freeSpace]
             filterSet: filterSet
             scanTime: [oldTree scanTime]];

  [oldTree release];

  [self handler: handler finishedParsingElement: filterSet];
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingFolderElement: (DirectoryItem *) dirItem {
  [tree setScanTree: dirItem];
  
  [self handler: handler finishedParsingElement: dirItem];
}
  
@end // @implementation ScanInfoElementHandler 


@implementation ScanCommentsElementHandler 

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
  if (self = [super initWithElement: elementNameVal reader: readerVal 
                      callback: callbackVal onSuccess: successSelectorVal]) {
    comments = [[NSMutableString alloc] initWithCapacity: 256];
  }
  
  return self;
}

- (void) dealloc {
  [comments release];
  
  [super dealloc];
}


- (id) objectForElement {
  return comments;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
  [comments appendString: string];
}

@end // @implementation ScanCommentsElementHandler


@implementation FilterSetElementHandler 

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
  if (self = [super initWithElement: elementNameVal reader: readerVal 
                      callback: callbackVal onSuccess: successSelectorVal]) {
    filterSet = [[FilterSet alloc] init];
  }
  
  return self;
}

- (void) dealloc {
  [filterSet release];
  
  [super dealloc];
}


- (void) handleChildElement: (NSString *)childElement 
           attributes: (NSDictionary *)attribs {
 if ([childElement isEqualToString: FilterElem]) {
    [[[FilterElementHandler alloc] 
         initWithElement: childElement reader: reader callback: self 
           onSuccess: @selector(handler:finishedParsingFilterElement:)]
             handleAttributes: attribs];
  }
  else {
    [super handleChildElement: childElement attributes: attribs];
  }
}

- (id) objectForElement {
  return filterSet;
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingFilterElement: (Filter *) filter {
  if ( [filter createFileItemTestFromRepository: [reader filterTestRepository]
                 unboundTests: [reader mutableUnboundFilterTests]] != nil) {
    FilterSet  *oldFilterSet = filterSet;
  
    filterSet = [[oldFilterSet filterSetWithNewFilter: filter] retain];
  
    [oldFilterSet release];
  }
  
  [self handler: handler finishedParsingElement: filter];
}

@end // @implementation FilterSetElementHandler


@implementation FilterElementHandler 

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
  if (self = [super initWithElement: elementNameVal reader: readerVal 
                      callback: callbackVal onSuccess: successSelectorVal]) {
    filterTests = [[NSMutableArray alloc] initWithCapacity: 8];;
    name = nil;
  }
  
  return self;
}

- (void) dealloc {
  [name release];
  [filterTests release];
  
  [super dealloc];
}


- (void) handleAttributes: (NSDictionary *)attribs {
  @try {
    name = [[self getStringAttributeValue: NameAttr from: attribs
                    defaultValue: nil] retain];
  }
  @catch (AttributeParseException *ex) {
    [self handlerAttributeParseError: ex];
  }
}

- (void) handleChildElement: (NSString *)childElement 
           attributes: (NSDictionary *)attribs {
 if ([childElement isEqualToString: FilterTestElem]) {
    [[[FilterTestElementHandler alloc] 
         initWithElement: childElement reader: reader callback: self 
           onSuccess: @selector(handler:finishedParsingFilterTestElement:)]
             handleAttributes: attribs];
  }
  else {
    [super handleChildElement: childElement attributes: attribs];
  }
}

- (id) objectForElement {
  return ( (name != nil)
           ? [Filter filterWithName: name filterTests: filterTests]
           : [Filter filterWithFilterTests: filterTests] );
}

- (void) handler: (ElementHandler *)handler 
           finishedParsingFilterTestElement: (FilterTestRef *) filterTest {
  [filterTests addObject: filterTest];
  
  [self handler: handler finishedParsingElement: filterTest];
}

@end // @implementation FilterElementHandler


@implementation FilterTestElementHandler 

- (id) initWithElement: (NSString *)elementNameVal
         reader: (TreeReader *)readerVal
         callback: (id) callbackVal
         onSuccess: (SEL) successSelectorVal {
  if (self = [super initWithElement: elementNameVal reader: readerVal 
                      callback: callbackVal onSuccess: successSelectorVal]) {
    filterTest = nil;
  }
  
  return self;
}

- (void) dealloc {
  [filterTest release];
  
  [super dealloc];
}


- (void) handleAttributes: (NSDictionary *)attribs {
  @try {
    NSString  *name = [self getStringAttributeValue: NameAttr from: attribs];
    
    BOOL  inv = [self getBooleanAttributeValue: InvertedAttr from: attribs
                        defaultValue: NO];

    filterTest = [[FilterTestRef alloc] initWithName: name inverted: inv];
  }
  @catch (AttributeParseException *ex) {
    [self handlerAttributeParseError: ex];
  }
}

- (id) objectForElement {
  return filterTest;
}

@end // @implementation FilterTestElementHandler


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

    files = [[[reader filesArrayPool] borrowObject] retain];
    dirs = [[[reader dirsArrayPool] borrowObject] retain];
  }
  
  return self;
}

- (void) dealloc {
  [parentItem release];
  [dirItem release];
  
  [[reader filesArrayPool] returnObject: files];
  [files release];

  [[reader dirsArrayPool] returnObject: dirs];
  [dirs release];
  
  [super dealloc];
}


- (void) handleAttributes: (NSDictionary *)attribs {
  @try {
    NSString  *name = [self getStringAttributeValue: NameAttr from: attribs];
    int  flags = [self getIntegerAttributeValue: FlagsAttr
                         from: attribs defaultValue: 0];

    dirItem = [[DirectoryItem allocWithZone: [parentItem zone]]
                  initWithName: name parent: parentItem flags: flags];
    [[reader progressTracker] processingFolder: dirItem];
  }
  @catch (AttributeParseException *ex) {
    [self handlerAttributeParseError: ex];
  }
}

- (void) handleChildElement: (NSString *)childElement 
           attributes: (NSDictionary *)attribs {
 if ([childElement isEqualToString: FileElem]) {
    [[[FileElementHandler alloc] 
         initWithElement: childElement reader: reader callback: self 
           onSuccess: @selector(handler:finishedParsingFileElement:) 
           parent: dirItem]
             handleAttributes: attribs];
  }
  else if ([childElement isEqualToString: FolderElem]) {
    [[[FolderElementHandler alloc] 
         initWithElement: childElement reader: reader callback: self 
           onSuccess: @selector(handler:finishedParsingFolderElement:) 
           parent: dirItem]
             handleAttributes: attribs];
  }
  else {
    [super handleChildElement: childElement attributes: attribs];
  }
}

- (id) objectForElement {
  TreeBalancer  *treeBalancer = [reader treeBalancer];

  [dirItem setDirectoryContents: 
    [CompoundItem 
       compoundItemWithFirst: [treeBalancer createTreeForItems: files] 
                      second: [treeBalancer createTreeForItems: dirs]]];

  [[reader progressTracker] processedFolder: dirItem];
  
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
  @try {
    NSString  *name = [self getStringAttributeValue: NameAttr from: attribs];
    int  flags = [self getIntegerAttributeValue: FlagsAttr
                         from: attribs defaultValue: 0];
    ITEM_SIZE  size = [self getItemSizeAttributeValue: SizeAttr from: attribs];
    
    UniformTypeInventory  *typeInventory = 
      [UniformTypeInventory defaultUniformTypeInventory];
    UniformType  *fileType = 
      [typeInventory uniformTypeForExtension: [name pathExtension]];

    fileItem = [[PlainFileItem allocWithZone: [parentItem zone]]
                   initWithName: name parent: parentItem size: size
                     type: fileType flags: flags];
  }
  @catch (AttributeParseException *ex) {
    [self handlerAttributeParseError: ex];
  }
}

- (id) objectForElement {
  return fileItem;
}

@end // @implementation FileElementHandler


@implementation AttributeParseException 

// Overrides designated initialiser.
- (id) initWithName: (NSString *)name reason: (NSString *)reason 
         userInfo: (NSDictionary *)userInfo {
  NSAssert(NO, @"Use -initWithAttributeName:reason: instead.");
}

- (id) initWithAttributeName: (NSString *)attribName 
         reason: (NSString *)reason {
  NSDictionary  *userInfo = 
    [NSDictionary dictionaryWithObject: attribName forKey: AttributeNameKey];

  return [super initWithName: @"AttributeParseException"
                  reason: reason 
                  userInfo: userInfo];
}

+ (id) exceptionWithAttributeName: (NSString *)attribName 
         reason: (NSString *)reason {
  return [[[AttributeParseException alloc]
              initWithAttributeName: attribName reason: reason] autorelease];
}

@end // @implementation AttributeParseException
