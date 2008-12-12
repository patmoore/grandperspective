#import "DirectoryViewToolbarControl.h"

#import "DirectoryViewControl.h"
#import "ItemPathModelView.h"


NSString  *ToolbarNavigation = @"Navigation"; 
NSString  *ToolbarSelection = @"Selection"; 
NSString  *ToolbarOpenItem = @"OpenItem";
NSString  *ToolbarDeleteItem = @"DeleteItem";
NSString  *ToolbarToggleInfoDrawer = @"ToggleInfoDrawer";


@interface DirectoryViewToolbarControl (PrivateMethods)

/* Registers that the given selector should be used for creating the toolbar
 * item with the given identifier.
 */
- (void) createToolbarItem: (NSString *)identifier 
            usingSelector: (SEL)selector;

- (NSToolbarItem *) navigationToolbarItem;
- (NSToolbarItem *) selectionToolbarItem;
- (NSToolbarItem *) openItemToolbarItem;
- (NSToolbarItem *) deleteItemToolbarItem;
- (NSToolbarItem *) toggleInfoDrawerToolbarItem;

- (id) validateNavigationControls;
- (id) validateSelectionControls;

- (BOOL) validateAction: (SEL)action;

- (void) zoomOut: (id) sender;
- (void) zoomIn: (id) sender;

- (void) moveFocusUp: (id) sender;
- (void) moveFocusDown: (id) sender;

- (void) openFileInFinder: (id) sender;
- (void) deleteFile: (id) sender;

@end


@interface ToolbarItemMenu : NSMenuItem {
}

- (id) initWithTitle: (NSString *)title target: (id) target;
- (void) addAction: (SEL) action withTitle: (NSString *)title;

@end


@interface SelectorObject : NSObject {
  SEL  selector;
}

- (id) initWithSelector: (SEL)selector;
- (SEL) selector;

@end


@interface ValidatingToolbarItem : NSToolbarItem {
  NSObject  *validator;
  SEL  validationSelector;
}

- (id) initWithItemIdentifier: (NSString *)identifier
         validator: (NSObject *)validator 
         validationSelector: (SEL) validationSelector;

@end


@implementation DirectoryViewToolbarControl

- (id) init {
  if (self = [super init]) {
    dirView = nil; // Will be set when loaded from nib.
  }
  return self;
}

- (void) dealloc {
  // We were not retaining it, so should not call -release  
  dirView = nil;

  [super dealloc];
}


- (void) awakeFromNib {
  // Not retaining it. It needs to be deallocated when the window is closed.
  dirView = [dirViewWindow windowController];
  
  NSToolbar  *toolbar = 
    [[[NSToolbar alloc] initWithIdentifier: @"DirectoryViewToolbar"] 
         autorelease];
           
  [toolbar setAllowsUserCustomization: YES];
  [toolbar setAutosavesConfiguration: YES];     
  [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];

  [toolbar setDelegate: self];
  [[dirView window] setToolbar: toolbar];
}


NSMutableDictionary  *createToolbarItemLookup = nil;

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
                     itemForItemIdentifier: (NSString *)itemIdentifier
                     willBeInsertedIntoToolbar: (BOOL)flag {
  NSLog(@"new toolbar item: %@", itemIdentifier);
  
  if (createToolbarItemLookup == nil) {
    createToolbarItemLookup = [[NSMutableDictionary alloc] initWithCapacity: 8];

    [self createToolbarItem: ToolbarNavigation
            usingSelector: @selector(navigationToolbarItem)];
    [self createToolbarItem: ToolbarSelection
            usingSelector: @selector(selectionToolbarItem)];
    [self createToolbarItem: ToolbarOpenItem 
            usingSelector: @selector(openItemToolbarItem)];
    [self createToolbarItem: ToolbarDeleteItem 
            usingSelector: @selector(deleteItemToolbarItem)];
    [self createToolbarItem: ToolbarToggleInfoDrawer
            usingSelector: @selector(toggleInfoDrawerToolbarItem)];
  }
  
  SEL  selector = 
    [[createToolbarItemLookup objectForKey: itemIdentifier] selector];
  
  NSToolbarItem  *item = [self performSelector: selector];

  if (! flag) {
    [item setTarget: nil];
  }

  return item;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
                      ToolbarNavigation, ToolbarSelection,
                      NSToolbarFlexibleSpaceItemIdentifier,  
                      ToolbarOpenItem, ToolbarDeleteItem, 
                      NSToolbarFlexibleSpaceItemIdentifier, 
                      ToolbarToggleInfoDrawer, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
                      ToolbarNavigation,
                      ToolbarSelection,
                      ToolbarOpenItem, ToolbarDeleteItem,
                      ToolbarToggleInfoDrawer, 
                      NSToolbarSeparatorItemIdentifier, 
                      NSToolbarSpaceItemIdentifier, 
                      NSToolbarFlexibleSpaceItemIdentifier, nil];
}


- (IBAction) navigationAction: (id) sender {
  if ([sender selectedSegment] == 0) {
    [self zoomOut: sender];
  }
  else if ([sender selectedSegment] == 1) {
    [self zoomIn: sender];
  }
}


- (IBAction) selectionAction: (id) sender {
  if ([sender selectedSegment] == 0) {
    [self moveFocusUp: sender];
  }
  else if ([sender selectedSegment] == 1) {
    [self moveFocusDown: sender];
  }
}

@end


@implementation DirectoryViewToolbarControl (PrivateMethods)

- (void) createToolbarItem: (NSString *)identifier 
            usingSelector: (SEL)selector {
  id  obj = [[[SelectorObject alloc] initWithSelector: selector] autorelease];

  [createToolbarItemLookup setObject: obj forKey: identifier];
}


- (NSToolbarItem *) navigationToolbarItem {
  NSToolbarItem  *item = 
    [[[ValidatingToolbarItem alloc] 
         initWithItemIdentifier: ToolbarNavigation validator: self
           validationSelector: @selector(validateNavigationControls)]
             autorelease];
             
  NSString  *title = 
    NSLocalizedStringFromTable( @"Zoom", @"Toolbar", 
                                @"Label for zooming controls" );
  NSString  *zoomOutTitle = 
    NSLocalizedStringFromTable( @"Zoom out", @"Toolbar", @"Toolbar action" );
  NSString  *zoomInTitle = 
    NSLocalizedStringFromTable( @"Zoom in", @"Toolbar", @"Toolbar action" );

  [item setLabel: title];
  [item setPaletteLabel: [item label]];
  [item setView: navigationControls];
  [item setMinSize: [navigationControls bounds].size];
  [item setMaxSize: [navigationControls bounds].size];
  
  // Tool tips set here (as opposed to Interface Builder) so that all toolbar-
  // related text is in the same file, to facilitate localization.
  [[navigationControls cell] setToolTip: zoomOutTitle forSegment: 0];
  [[navigationControls cell] setToolTip: zoomInTitle  forSegment: 1];

  ToolbarItemMenu  *menu = 
    [[[ToolbarItemMenu alloc] initWithTitle: title target: self] autorelease];
  [menu addAction: @selector(zoomOut:) withTitle: zoomOutTitle];
  [menu addAction: @selector(zoomIn:) withTitle: zoomInTitle];

  [item setMenuFormRepresentation: menu];

  return item;
}

- (NSToolbarItem *) selectionToolbarItem {
  NSToolbarItem  *item = 
    [[[ValidatingToolbarItem alloc] 
         initWithItemIdentifier: ToolbarSelection validator: self
           validationSelector: @selector(validateSelectionControls)]
             autorelease];
             
  NSString  *title = 
    NSLocalizedStringFromTable( @"Select", @"Toolbar", 
                                @"Label for selection controls" );
  NSString  *moveUpTitle =
    NSLocalizedStringFromTable( @"Move focus up", @"Toolbar", 
                                @"Toolbar action" );
  NSString  *moveDownTitle =
    NSLocalizedStringFromTable( @"Move focus down", @"Toolbar", 
                                @"Toolbar action" );

  [item setLabel: title];
  [item setPaletteLabel: [item label]];
  [item setView: selectionControls];
  [item setMinSize: [selectionControls bounds].size];
  [item setMaxSize: [selectionControls bounds].size];

  // Tool tips set here (as opposed to Interface Builder) so that all toolbar-
  // related text is in the same file, to facilitate localization.
  [[selectionControls cell] setToolTip: moveUpTitle forSegment: 0];
  [[selectionControls cell] setToolTip: moveDownTitle forSegment: 1];

  ToolbarItemMenu  *menu = 
    [[[ToolbarItemMenu alloc] initWithTitle: title target: self] autorelease];
  [menu addAction: @selector(moveFocusUp:) withTitle: moveUpTitle];
  [menu addAction: @selector(moveFocusDown:) withTitle: moveDownTitle];

  [item setMenuFormRepresentation: menu];

  return item;
}

- (NSToolbarItem *) openItemToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] 
         initWithItemIdentifier: ToolbarOpenItem] autorelease];

  [item setLabel: NSLocalizedStringFromTable( @"Open", @"Toolbar", 
                                              @"Toolbar action" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable( @"Open in Finder", @"Toolbar", 
                                                @"Tooltip" )];
  [item setImage: [NSImage imageNamed: @"OpenInFinder.png"]];
  [item setAction: @selector(openFileInFinder:) ];
  [item setTarget: self];

  return item;
}

- (NSToolbarItem *) deleteItemToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] 
         initWithItemIdentifier: ToolbarDeleteItem] autorelease];

  [item setLabel: NSLocalizedStringFromTable( @"Delete", @"Toolbar",
                                              @"Toolbar action" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable( @"Move to trash", @"Toolbar", 
                                                @"Tooltip" ) ];
  [item setImage: [NSImage imageNamed: @"Delete.tiff"]];
  [item setAction: @selector(deleteFile:) ];
  [item setTarget: self];

  return item;
}

- (NSToolbarItem *) toggleInfoDrawerToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarToggleInfoDrawer] 
         autorelease];

  [item setLabel: NSLocalizedStringFromTable( @"Drawer", @"Toolbar",
                                              @"Toolbar action" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable( @"Open/close drawer", 
                                                @"Toolbar", "Tooltip" )];
  [item setImage: [NSImage imageNamed: @"ToggleDrawer.png"]];
  [item setAction: @selector(toggleDrawer:) ];
  [item setTarget: dirView];

  return item;
}


- (id) validateNavigationControls {
  [navigationControls setEnabled: [dirView canNavigateUp] forSegment: 0];
  [navigationControls setEnabled: [dirView canNavigateDown] forSegment: 1];

  return self; // Always enable the overall control
}

- (id) validateSelectionControls {
  ItemPathModelView  *pathModelView = [dirView pathModelView]; 

  [selectionControls setEnabled: [pathModelView canMoveSelectionUp] 
                       forSegment: 0];
  [selectionControls setEnabled: ! [pathModelView selectionSticksToEndPoint] 
                       forSegment: 1];
  return self; // Always enable the overall control
}


- (BOOL) validateToolbarItem: (NSToolbarItem *)item {
  // NSLog(@"validateToolbarItem: %@", [item label] );

  return [self validateAction: [item action]];
}

- (BOOL) validateMenuItem: (NSMenuItem *)item {
  // NSLog(@"validateMenuItem: %@", [item title] );
  
  return [self validateAction: [item action]];
}
  

- (BOOL) validateAction: (SEL)action {
  if ( action == @selector(zoomOut:) ) {
    return [dirView canNavigateUp];
  }
  else if ( action == @selector(zoomIn:) ) {
    return [dirView canNavigateDown];
  }
  if ( action == @selector(moveFocusUp:) ) {
    return [[dirView pathModelView] canMoveSelectionUp];
  }
  else if ( action == @selector(moveFocusDown:) ) {
    return ! [[dirView pathModelView] selectionSticksToEndPoint];
  }
  else if ( action == @selector(openFileInFinder:) ) {
    return [dirView canRevealSelectedFile];
  }
  else if ( action == @selector(deleteFile:) ) {
    return [dirView canDeleteSelectedFile];
  }
  else {
    return NO;
  }
}


- (void) zoomOut: (id) sender {
  [dirView upAction: sender];
}

- (void) zoomIn: (id) sender {
  [dirView downAction: sender];
}


- (void) moveFocusUp: (id) sender {
  [[dirView pathModelView] moveSelectionUp];
}

- (void) moveFocusDown: (id) sender {
  ItemPathModelView  *pathModelView = [dirView pathModelView];
  
  if ([pathModelView canMoveSelectionDown]) {
    [pathModelView moveSelectionDown];
  }
  else {
    [pathModelView setSelectionSticksToEndPoint: YES];
  }
}


- (void) openFileInFinder: (id) sender {
  [dirView openFileInFinder: sender];
}

- (void) deleteFile: (id) sender {
  [dirView deleteFile: sender];
}

@end // @implementation DirectoryViewToolbarControl (PrivateMethods)


@implementation ToolbarItemMenu

- (id) initWithTitle: (NSString *)title {
  return [self initWithTitle: title target: nil];
}

- (id) initWithTitle: (NSString *)title target: (id) target {
  if (self = [super init]) {
    [self setTitle: title];
    [self setTarget: target]; // Using target for setting target of subitems.
    
    NSMenu  *submenu = [[[NSMenu alloc] initWithTitle: title] autorelease];
    [submenu setAutoenablesItems: YES];

    [self setSubmenu: submenu];
  }
  
  return self;
}


- (void) addAction: (SEL) action withTitle: (NSString *)title {
  NSMenuItem  *item =
    [[[NSMenuItem alloc] 
        initWithTitle: title action: action keyEquivalent: @""] autorelease];
  [item setTarget: [self target]];
  [[self submenu] addItem: item];
}

@end // @implementation ToolbarItemMenu


@implementation ValidatingToolbarItem

- (id) initWithItemIdentifier: (NSString *)identifier
         validator: (NSObject *)validatorVal 
         validationSelector: (SEL) validationSelectorVal {
  if (self = [super initWithItemIdentifier: identifier]) {
    validator = [validatorVal retain];
    validationSelector = validationSelectorVal;
  }
  return self;
}

- (void) dealloc {
  [validator release];
  
  [super dealloc];
}


- (void) validate {
  // Any non-nil value means that the control should be enabled.
  [self setEnabled: [validator performSelector: validationSelector] != nil];
}

@end // @implementation ValidatingToolbarItem


@implementation SelectorObject

- (id) initWithSelector: (SEL)selectorVal {
  if (self = [super init]) {
    selector = selectorVal;
  }
  return self;
}


- (SEL) selector {
  return selector;
}

@end // @implementation SelectorObject


