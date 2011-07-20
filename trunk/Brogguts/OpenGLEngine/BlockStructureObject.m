//
//  BlockStructure.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 2/24/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "BlockStructureObject.h"
#import "Image.h"
#import "Global.h"
#import "BroggutScene.h"

@implementation BlockStructureObject

- (id)initWithLocation:(CGPoint)location isTraveling:(BOOL)traveling {
	self = [super initWithTypeID:kObjectStructureBlockID withLocation:location isTraveling:traveling];
	if (self) {
        hasBeenAdded = NO;
        objectImage.scale = Scale2fMake(1.0f, 1.0f);
	}
	return self;
}

- (void)updateObjectLogicWithDelta:(float)aDelta {
    [super updateObjectLogicWithDelta:aDelta];
    if (!hasBeenAdded && !isTraveling) {
        hasBeenAdded = YES;
        [[self currentScene] addBlock:self];
    }
}

@end