//
//  SideBarObject.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 2/12/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "SideBarController.h"
#import "SideBarObject.h"
#import "MainMenuSideBar.h"
#import "BitmapFont.h"
#import "Image.h"
#import "ImageRenderSingleton.h"
#import "CraftUpgradesSideBar.h"
#import "StructureUpgradesSideBar.h"
#import "GameController.h"

@implementation SideBarController

@synthesize isSideBarShowing, sideBarFont, isShowingUpgradeSideBar;

- (void)dealloc {
    [sideBarBackButtonImage release];
    [sideBarButtonImage release];
	[sideBarFont release];
	[super dealloc];
}

- (id)initWithLocation:(CGPoint)location withWidth:(float)width withHeight:(float)height {
	self = [super init];
	if (self) {
        sideBarButtonImage = [[Image alloc] initWithImageNamed:@"spritesidebarbutton.png" filter:GL_LINEAR];
        [sideBarButtonImage setRenderLayer:kLayerHUDBottomLayer];
        sideBarBackButtonImage = [[Image alloc] initWithImageNamed:@"spritesidebarback.png" filter:GL_LINEAR];
        [sideBarBackButtonImage setRenderLayer:kLayerHUDTopLayer];
		isSideBarShowing = NO;
		isSideBarMovingIn = NO;
		isSideBarMovingOut = NO;
		sideBarLocation = location;
		originalLocation = location;
        isShowingUpgradeSideBar = NO;
		sideBarWidth = width;
		sideBarHeight = height;
		sideBarStack = [[NSMutableArray alloc] init];
		sideBarObjectLocation = location;
		sideBarFont = [[BitmapFont alloc] initWithFontImageNamed:@"gothic.png" controlFile:@"gothic" scale:Scale2fMake(1.0f, 1.0f) filter:GL_LINEAR];
		[sideBarFont setFontColor:Color4fMake(1.0f, 1.0f, 1.0f, 1.0f)];
		MainMenuSideBar* topTemp = [[MainMenuSideBar alloc] init];
		[topTemp setMyController:self];
		[sideBarStack addObject:topTemp];
		[topTemp release];
	}
	return self;
}

- (BOOL)isSideBarShowing {
	if (isSideBarShowing && !isSideBarMovingIn && !isSideBarMovingOut) {
		return YES;
	}
	return NO;
}

- (CGRect)sideBarRect {
	return CGRectMake(sideBarLocation.x, sideBarLocation.y, sideBarWidth, sideBarHeight);
}

- (CGRect)buttonRect {
    if (sideBarButtonLocation == 0) { // top
        return CGRectMake(sideBarLocation.x + sideBarWidth,
                          sideBarLocation.y + sideBarHeight - SIDEBAR_BUTTON_HEIGHT,
                          SIDEBAR_BUTTON_WIDTH,
                          SIDEBAR_BUTTON_HEIGHT); // Width and height of the button are hardcoded
    } else {
        return CGRectMake(sideBarLocation.x + sideBarWidth,
                          sideBarLocation.y,
                          SIDEBAR_BUTTON_WIDTH,
                          SIDEBAR_BUTTON_HEIGHT); // Width and height of the button are hardcoded
    }
	
}

- (void)moveSideBarIn {
	if (!isSideBarShowing) {
		if (!isSideBarMovingOut) {
			isSideBarShowing = YES;
			isSideBarMovingIn = YES;
			isSideBarMovingOut = NO;
		}
	}
}

- (void)moveSideBarOut {
	if (isSideBarShowing) {
		if (!isSideBarMovingIn) {
			isSideBarShowing = YES;
			isSideBarMovingIn = NO;
			isSideBarMovingOut = YES;
		}
	}
}

- (void)updateSideBar {
    if (isSideBarMovingIn) {
        sideBarLocation = CGPointMake(sideBarLocation.x + SIDEBAR_MOVE_SPEED, sideBarLocation.y);
        if (sideBarLocation.x >= originalLocation.x + sideBarWidth) {
            isSideBarMovingIn = NO;
            sideBarLocation = CGPointMake(originalLocation.x + sideBarWidth, sideBarLocation.y);
        }
        sideBarObjectLocation = sideBarLocation;
    }
    if (isSideBarMovingOut) {
        sideBarLocation = CGPointMake(sideBarLocation.x - SIDEBAR_MOVE_SPEED, sideBarLocation.y);
        if (sideBarLocation.x <= originalLocation.x) {
            isSideBarMovingOut = NO;
            isSideBarShowing = NO;
            sideBarLocation = CGPointMake(originalLocation.x, sideBarLocation.y);
        }
        sideBarObjectLocation = sideBarLocation;
    }
    
    if (!isMovingObjectIn && !isMovingObjectOut) {
        sideBarObjectLocation = sideBarLocation;
    }
    
    SideBarObject* topObject = [sideBarStack objectAtIndex:([sideBarStack count] - 1)];
    
    if ([topObject isKindOfClass:[CraftUpgradesSideBar class]] ||
        [topObject isKindOfClass:[StructureUpgradesSideBar class]]) { // OR STRUCTURE UPGRADES
        isShowingUpgradeSideBar = YES;
    } else {
        isShowingUpgradeSideBar = NO;
    }
    
    [topObject updateSideBar];
    
    if (!isSideBarMovingIn && !isSideBarMovingOut) {
        // update the current object on the top of the stack
        if (topObject) {
            if (isMovingObjectIn) {
                isMovingObjectOut = NO;
                sideBarObjectLocation = CGPointMake(sideBarObjectLocation.x + SIDEBAR_MOVE_SPEED, sideBarObjectLocation.y);
                if (sideBarObjectLocation.x >= sideBarLocation.x) {
                    sideBarObjectLocation = sideBarLocation;
                    isMovingObjectIn = NO;
                }
            }
            if (isMovingObjectOut) {
                isMovingObjectIn = NO;
                sideBarObjectLocation = CGPointMake(sideBarObjectLocation.x - SIDEBAR_MOVE_SPEED, sideBarObjectLocation.y);
                if (sideBarObjectLocation.x <= sideBarLocation.x - sideBarWidth) {
                    sideBarObjectLocation = CGPointMake(sideBarLocation.x - sideBarWidth, sideBarLocation.y);
                    isMovingObjectOut = NO;
                    [sideBarStack removeLastObject];
                }
            }
        }
    }
    
    if (isSideBarShowing) {
        [sideBarButtonImage setFlipHorizontally:YES];
	} else {
        [sideBarButtonImage setFlipHorizontally:NO];
    }
}

- (CGRect)backButtonRect {
	CGRect rect = CGRectMake(sideBarLocation.x,
							 sideBarLocation.y + sideBarHeight - SIDEBAR_BUTTON_HEIGHT,
							 SIDEBAR_BUTTON_WIDTH,
							 SIDEBAR_BUTTON_HEIGHT);
	return rect;
}

- (CGPoint)backButtonPoint {
	CGPoint point = CGPointMake(sideBarLocation.x + 32,
                                sideBarLocation.y + sideBarHeight - 32);
	return point;
}

- (void)renderSideBar {
	CGRect buttonRect = [self buttonRect];
    
    [sideBarButtonImage renderAtPoint:buttonRect.origin];
	static float colors[24] = {
        0.0f, 0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 0.0f, 0.0f,
    };
    
    if (isSideBarShowing) {
        enablePrimitiveDraw();
        drawFilledRectWithColors([self sideBarRect], Vector2fZero, colors);
        disablePrimitiveDraw();
        SideBarObject* topObject = [sideBarStack objectAtIndex:([sideBarStack count] - 1)];
        [topObject renderWithOffset:Vector2fMake(-sideBarObjectLocation.x, -sideBarObjectLocation.y)];
    }
	
	if ([sideBarStack count] > 1) {
		// Draw the back button
        [sideBarBackButtonImage renderCenteredAtPoint:[self backButtonPoint]];
	}
}

- (void)pushSideBarObject:(SideBarObject*)sideBar {
    if (isShowingUpgradeSideBar) {
        [sideBarStack removeLastObject];
    }
	[sideBarStack addObject:sideBar];
	isMovingObjectIn = YES;
	isMovingObjectOut = NO;
	sideBarObjectLocation = CGPointMake(sideBarLocation.x + sideBarWidth, sideBarLocation.y);
}

- (void)popSideBarObject {
	isMovingObjectIn = NO;
	isMovingObjectOut = YES;
}

- (void)touchesBeganAtLocation:(CGPoint)location {
	if (!isSideBarMovingIn && !isSideBarMovingOut &&
		!isMovingObjectIn && !isMovingObjectOut) {
		SideBarObject* topObject = [sideBarStack objectAtIndex:([sideBarStack count] - 1)];
		[topObject touchesBeganAtLocation:location];
	}
}

- (void)touchesMovedToLocation:(CGPoint)toLocation from:(CGPoint)fromLocation {
	if (!isSideBarMovingIn && !isSideBarMovingOut &&
		!isMovingObjectIn && !isMovingObjectOut) {
		SideBarObject* topObject = [sideBarStack objectAtIndex:([sideBarStack count] - 1)];
		[topObject touchesMovedToLocation:toLocation from:fromLocation];
	}
}

- (void)touchesEndedAtLocation:(CGPoint)location {
	if (!isSideBarMovingIn && !isSideBarMovingOut &&
		!isMovingObjectIn && !isMovingObjectOut) {
		SideBarObject* topObject = [sideBarStack objectAtIndex:([sideBarStack count] - 1)];
		if ([sideBarStack count] > 1) {
			if (CGRectContainsPoint([self backButtonRect], location)) {
				[self popSideBarObject];
				return;
			}
		}
		if (topObject.scrollTouchTimer > 0) {
			[topObject touchesTappedAtLocation:location];
		} else {
			[topObject touchesEndedAtLocation:location];
		}
	}
}

- (void)touchesDoubleTappedAtLocation:(CGPoint)location {
	if (!isSideBarMovingIn && !isSideBarMovingOut &&
		!isMovingObjectIn && !isMovingObjectOut) {
		SideBarObject* topObject = [sideBarStack objectAtIndex:([sideBarStack count] - 1)];
		[topObject touchesDoubleTappedAtLocation:location];
	}
}

@end
