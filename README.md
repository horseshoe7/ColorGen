# ColorPaletteGenerator

ColorPaletteGenerator is a tool that takes a human-readable input file describing a color palette, and generates the associated code / assets that an Xcode project can use.

This is the successor to the RMRColorTools project that was written in Objective-C and has some legacy aspects to it that just aren't necessary.  It is intended to be used in exactly the same way, but be available via the Swift Package Manager.

In the input file, you can declare:

- A hex color value and provide it a label
- 2 hex color values for one label, if you need different colors for 'dark mode' on iOS
- Aliases to previously declared colors, so you can define a color and give it an abstract name, but use an alias for a specific purpose (i.e. navigationBarTitle)


The Input File will ultimately generate:

- An .xcassets Assets Catalog with the colors (so to be available to Interface Builder)
- A namespaced struct that contains all the color definitions as Constants that will reference these Colors in the asset catalog.
- You can specify whether this namespaced struct has a public ACL or is internal (default).


## Input File Format

```
// MyAppColors.palette
//
// Lines beginning with // are ignored by the parser, so you can add comments for your team members.
//
// Or you can make comments be generated into the output file by adding them after the color name (see below)


// Define an opaque color in RRGGBB Hex Format. e.g. #FFEE24.   (# character is required!)
#RRGGBB ColorName Add some comments that should be generated into the output file.

// Or in RRGGBBAA format if you need transparency
#RRGGBBAA ColorNameTranslucent

// Perhaps you want to support Dark Mode.  Just add a second hex value after the first one.  The first is always 'Any' and the second is for dark mode.
#FF0000 #AA0000 Red You can see that the second value is darker than the first


// Create an Alias to an already defined color.  You can see the pattern: $ExistingColorname AliasName.  ($ character required!)
$ColorName MainTitleText

// You should ideally define your colors at the top, and all aliases below them!

``
 
