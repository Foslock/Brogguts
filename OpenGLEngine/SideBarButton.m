//
//  SideBarButton.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 2/24/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "SideBarButton.h"
#import "TiledButtonObject.h"

@implementation SideBarButton
@synthesize buttonText, buttonHeight, buttonWidth, buttonCenter, isPressed, isDisabled, button, textColor, textScale;

- (void)dealloc {
    [button release];
    [super dealloc];
}

- (id)initWithWidth:(float)width withHeight:(float)height withCenter:(CGPoint)center {
	self = [super init];
	if (self) {
		buttonWidth = (int)width;
		buttonHeight = (int)height;
		buttonCenter = center;
        isDisabled = NO;
        textColor = Color4fOnes;
        textScale = Scale2fMake(1.0f, 1.0f);
        button = [[TiledButtonObject alloc] initWithRect:[self buttonRect]];
	}
	return self;
}

- (Color4f)textColor {
    if (isDisabled) {
        return Color4fMake(0.5f, 0.5f, 0.5f, 0.8f);
    } else {
        return textColor;
    }
}

- (void)setIsDisabled:(BOOL)disabled {
    isDisabled = disabled;
    [button setIsDisabled:disabled];
}

- (void)setIsPressed:(BOOL)pressed {
    if (!isDisabled) {
        isPressed = pressed;
        [button setIsPushed:pressed];
    }
}

- (CGRect)buttonRect {
	return CGRectMake((int)(buttonCenter.x - buttonWidth / 2),
					  (int)(buttonCenter.y - buttonHeight / 2),
					  buttonWidth + (buttonWidth % 2),
					  buttonHeight + (buttonHeight % 2));
}

- (void)renderButtonWithScroll:(Vector2f)scroll {
    [button setDrawRect:[self buttonRect]];
    [button renderCenteredAtPoint:buttonCenter withScrollVector:scroll];
}

@end
