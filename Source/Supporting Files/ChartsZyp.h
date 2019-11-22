//
//  ChartsZypZyp.h
//  ChartsZypZyp
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ChartsZypZyp
//

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_IPHONE_SIMULATOR
	#import <UIKit/UIKit.h>
#else
    #import <Cocoa/Cocoa.h>
#endif

//! Project version number for ChartsZypZyp.
FOUNDATION_EXPORT double ChartsZypZypVersionNumber;

//! Project version string for ChartsZypZyp.
FOUNDATION_EXPORT const unsigned char ChartsZypZypVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ChartsZypZyp/PublicHeader.h>


