#import "ColorListCreator.h"


@interface ColorListCreator (PrivateMethods) 

+ (void) createCoffeeBeans;
+ (void) createPastelPapageno;
+ (void) createBlueSkyTulips;
+ (void) createMonaco;
+ (void) createWarmFall;
+ (void) createMossAndLichen;
+ (void) createMatbord;
+ (void) createBujumbura;
+ (void) createAutumn;
+ (void) createOliveSunset;
+ (void) createColorFile: (NSString*)name hexColors: (NSArray*) colors;

@end

static NSString*  hexChars = @"0123456789ABCDEF";

float valueOfHexPair(NSString* hexString) {
  int  val = 0;
  int  i;
  for (i = 0; i < [hexString length]; i++) { 
    val = val * 16;
    NSRange  r = [hexChars rangeOfString: 
                    [hexString substringWithRange: NSMakeRange(i, 1)]
                           options: NSCaseInsensitiveSearch];
    val += r.location;
  }
  
  return (val / 255.0);
}


NSColor* colorForHexString(NSString* hexColor) {
  float  r = valueOfHexPair([hexColor substringWithRange: NSMakeRange(0, 2)]);
  float  g = valueOfHexPair([hexColor substringWithRange: NSMakeRange(2, 2)]);
  float  b = valueOfHexPair([hexColor substringWithRange: NSMakeRange(4, 2)]);

  NSLog(@"%f, %f, %f", r, g, b);

  return [NSColor colorWithDeviceRed:r green:g blue:b alpha:0];
}


@implementation ColorListCreator

+ (void) createColorListFiles {
  [self createCoffeeBeans];
  [self createPastelPapageno];
  [self createBlueSkyTulips];
  [self createMonaco];
  [self createWarmFall];
  [self createMossAndLichen];
  [self createMatbord];
  [self createBujumbura];
  [self createAutumn];
  [self createOliveSunset];
}

@end

@implementation ColorListCreator (PrivateMethods)

+ (void) createCoffeeBeans {
  NSArray  *colors = 
    [NSArray arrayWithObjects: @"CC3333", @"CC9933", @"FFCC66", @"CC6633",
               @"CC6666", @"993300", @"666600", nil];
               
  [self createColorFile: @"CoffeeBeans" hexColors: colors];
}

+ (void) createPastelPapageno {
  NSArray  *colors = 
    [NSArray arrayWithObjects: @"66FF99", @"FFEB66", @"FFAC66", @"FF66AB",
               @"66C4FF", nil];
               
  [self createColorFile: @"PastelPapageno" hexColors: colors];
}

+ (void) createBlueSkyTulips {
  NSArray  *colors = 
    [NSArray arrayWithObjects: @"99CC66", @"336600", @"333399", @"CC6666",
               @"FF99CC", @"FF3333", @"FFCC66", nil];
               
  [self createColorFile: @"BlueSkyTulips" hexColors: colors];
}

+ (void) createMonaco {
  NSArray  *colors = 
    [NSArray arrayWithObjects: @"7378D4", @"2A91D2", @"3DBFCC", @"38B236",
               @"D92130", @"DB4621", @"EC8921", nil];
               
  [self createColorFile: @"Monaco" hexColors: colors];}


+ (void) createWarmFall {  
  NSArray  *colors = 
    [NSArray arrayWithObjects: @"CCCC00", @"999900", @"666600", @"333300",
               @"CC6600", @"996600", @"663300", @"FF6600", @"FF9900", @"FFCC00",
               nil];

  [self createColorFile: @"WarmFall" hexColors: colors];
}

+ (void) createMossAndLichen {
  NSArray  *colors = 
    [NSArray arrayWithObjects: @"666633", @"999966", @"CCCC99", @"FFFFCC",
               @"99CCCC", @"009999", @"006666", @"003333", nil];
               
  [self createColorFile: @"MossAndLichen" hexColors: colors];
}

+ (void) createMatbord {
  NSArray  *colors = 
    [NSArray arrayWithObjects: @"ABA64B", @"FFD06B", @"D17F58", @"B7081A",
               @"292C31", nil];
               
  [self createColorFile: @"DiningTable" hexColors: colors];
}

+ (void) createBujumbura {
  NSArray  *colors = 
    [NSArray arrayWithObjects: @"BE420E", @"BE6D0E", @"6B4F2E", @"CCA066",
               @"E0D752", @"A5BE0E", @"4197E3", nil];
               
  [self createColorFile: @"Bujumbura" hexColors: colors];
}

+ (void) createAutumn {
  NSArray  *colors = 
    [NSArray arrayWithObjects: @"666633", @"336666", @"993333", @"FFCC00",
               @"FF9900", nil];
               
  [self createColorFile: @"Autumn" hexColors: colors];
}

+ (void) createOliveSunset {
  NSArray  *colors = 
    [NSArray arrayWithObjects: @"99CCCC", @"3399CC", @"006699", @"003366",
               @"666600", @"999900", @"CCCC33", @"CCCC99", @"FFFFCC", @"FF9966",
               @"CC0033", @"990033", nil];
               
  [self createColorFile: @"OliveSunset" hexColors: colors];
}

+ (void) createColorFile: (NSString*)name hexColors: (NSArray*) colors {
  NSColorList  *colorList = [[NSColorList alloc] initWithName: name];

  int  i = 0;
  while (i < [colors count]) {
    NSString  *colorString = [colors objectAtIndex:i];
    
    [colorList insertColor: colorForHexString( colorString )
                 key: colorString atIndex: i++];
  }

  [colorList writeToFile: nil];
}

@end // @implementation ColorListCreator (PrivateMethods)
