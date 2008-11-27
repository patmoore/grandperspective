#import "DirectoryViewToolbarControl.h"

#import "DirectoryViewControl.h"


NSString  *ToolbarNavigateUp = @"NavigateUp";
NSString  *ToolbarNavigateDown = @"NavigateDown"; 
NSString  *ToolbarOpenItem = @"OpenItem";
NSString  *ToolbarDeleteItem = @"DeleteItem";
NSString  *ToolbarToggleInfoDrawer = @"ToggleInfoDrawer";


@interface DirectoryViewToolbarControl (PrivateMethods)

- (NSToolbarItem *) masterToolbarItemForIdentifier: identifier;

@end


@implementation DirectoryViewToolbarControl

- (id) initWithDirectoryView: (DirectoryViewControl *)dirViewVal {
  if (self = [super init]) {
    dirView = [dirViewVal retain];
    
    NSToolbar  *toolbar = 
      [[[NSToolbar alloc] initWithIdentifier: @"DirectoryViewToolbar"] 
           autorelease];
           
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];     
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];

    [toolbar setDelegate: self];
    [[dirView window] setToolbar: toolbar];
  }
  
  return self;
}

- (void) dealloc {
  [dirView release];
  
  [super dealloc];
}



- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
                     itemForItemIdentifier: (NSString *)itemIdentifier
                     willBeInsertedIntoToolbar: (BOOL)flag {
  NSToolbarItem  *newItem = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] 
         autorelease];
  NSToolbarItem  *masterItem = 
    [self masterToolbarItemForIdentifier: itemIdentifier];
    
  [newItem setLabel: [masterItem label]];
  [newItem setPaletteLabel: [masterItem paletteLabel]];
  NSView  *view = [masterItem view];
  if (view != nil) {
	[newItem setView: view];
	[newItem setMinSize: [view bounds].size];
	[newItem setMaxSize: [view bounds].size];
  }
  else {
	[newItem setImage: [masterItem image]];
  }

  [newItem setToolTip: [masterItem toolTip]];
  [newItem setAction: [masterItem action]];
  [newItem setMenuFormRepresentation: [masterItem menuFormRepresentation]];

  [newItem setTarget: dirView];

  return newItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
                      ToolbarNavigateUp, ToolbarNavigateDown,
                      NSToolbarFlexibleSpaceItemIdentifier,  
                      ToolbarOpenItem, ToolbarDeleteItem, 
                      NSToolbarFlexibleSpaceItemIdentifier, 
                      ToolbarToggleInfoDrawer, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
                      ToolbarNavigateUp, ToolbarNavigateDown, 
                      ToolbarOpenItem, ToolbarDeleteItem,
                      ToolbarToggleInfoDrawer, 
                      NSToolbarSeparatorItemIdentifier, 
                      NSToolbarFlexibleSpaceItemIdentifier, nil];
}

@end


@implementation DirectoryViewToolbarControl (PrivateMethods)

NSMutableDictionary  *masterToolbarItems;

- (NSToolbarItem *) masterToolbarItemForIdentifier: identifier {
  if (masterToolbarItems == nil) {
    masterToolbarItems = [[NSMutableDictionary alloc] initWithCapacity: 8];
    
    NSToolbarItem  *item;

    // Navigate Up 
    item = [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarNavigateUp] 
                autorelease];
    [item setLabel: NSLocalizedString( @"Up", 
                                       @"Toolbar label for navigating up" )];
    [item setPaletteLabel: [item label]];
    [item setToolTip: NSLocalizedString( @"Navigate up", "Tooltip" ) ];
    [item setImage: [NSImage imageNamed: @"Up.png"]];
    [item setAction: @selector(upAction:) ];

    [masterToolbarItems setObject: item forKey: [item itemIdentifier]];
    
    // Navigate Up 
    item = [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarNavigateDown] 
                autorelease];
    [item setLabel: NSLocalizedString( @"Down", 
                                       @"Toolbar label for navigating down" )];
    [item setPaletteLabel: [item label]];
    [item setToolTip: NSLocalizedString( @"Navigate down", "Tooltip" ) ];
    [item setImage: [NSImage imageNamed: @"Down.png"]];
    [item setAction: @selector(downAction:) ];

    [masterToolbarItems setObject: item forKey: [item itemIdentifier]];
    
    // Open item 
    item = [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarOpenItem] 
                autorelease];
    [item setLabel: NSLocalizedString( @"Open", 
                                       @"Toolbar label for Open in Finder" )];
    [item setPaletteLabel: [item label]];
    [item setToolTip: NSLocalizedString( @"Open in Finder", "Tooltip" ) ];
    [item setImage: [NSImage imageNamed: @"FinderIcon.png"]];
    [item setAction: @selector(openFileInFinder:) ];

    [masterToolbarItems setObject: item forKey: [item itemIdentifier]];
    
    // Delete item 
    item = [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarDeleteItem] 
                autorelease];
    [item setLabel: NSLocalizedString( @"Delete", 
                                       @"Toolbar label for deleting item" )];
    [item setPaletteLabel: [item label]];
    [item setToolTip: NSLocalizedString( @"Move to trash", "Tooltip" ) ];
    [item setImage: [NSImage imageNamed: @"Delete.tiff"]];
    [item setAction: @selector(deleteFile:) ];

    [masterToolbarItems setObject: item forKey: [item itemIdentifier]];
    
    // Toggle Info drawer
    item = [[[NSToolbarItem alloc] 
                initWithItemIdentifier: ToolbarToggleInfoDrawer] autorelease];
    [item setLabel: NSLocalizedString( @"Info", 
                                       @"Toolbar label for toggling Info drawer" )];
    [item setPaletteLabel: [item label]];
    [item setToolTip: NSLocalizedString( @"Show/hide drawer", "Tooltip" ) ];
    // TODO (eventually): Use "NSImageNameInfo" (Only available since 10.5)
    [item setImage: [NSImage imageNamed: @"Info.tiff"]];
    [item setAction: @selector(toggleDrawer:) ];

    [masterToolbarItems setObject: item forKey: [item itemIdentifier]];
  }

  return [masterToolbarItems objectForKey: identifier];
}

@end // @implementation DirectoryViewToolbarControl (PrivateMethods)

