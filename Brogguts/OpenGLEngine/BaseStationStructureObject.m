//
//  BaseStationStructure.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 2/24/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "BaseStationStructureObject.h"
#import "GameController.h"
#import "BroggutScene.h"
#import "CraftAndStructures.h"
#import "Global.h"
#import "Image.h"
#import "ImageRenderSingleton.h"
#import "CollisionManager.h"

@implementation BaseStationStructureObject

- (void)dealloc {
    [blinkingStructureLightImage release];
    [super dealloc];
}

- (id)initWithLocation:(CGPoint)location isTraveling:(BOOL)traveling {
	self = [super initWithTypeID:kObjectStructureBaseStationID withLocation:location isTraveling:traveling];
	if (self) {
		isCheckedForRadialEffect = YES;
		isTouchable = NO;
        blinkingStructureLightImage = [[Image alloc] initWithImageNamed:@"defaultTexture.png" filter:GL_LINEAR];
        [blinkingStructureLightImage setScale:Scale2fMake(0.25f, 0.25f)];
        [blinkingStructureLightImage setRenderLayer:kLayerTopLayer];
        rotationCounter = 0.0f;
        blinkCounter = 0.0f;
        lightPositionCounter = 0.0f;
        CollisionManager* manager = [[self currentScene] collisionManager];
        for (int i = 0; i < BASE_STATION_WIDTH_CELLS; i++) {
            for (int j = 0; j < BASE_STATION_HEIGHT_CELLS; j++) {
                int xIndex = i - (BASE_STATION_WIDTH_CELLS / 2);
                int yIndex = j - (BASE_STATION_HEIGHT_CELLS / 2);
                CGPoint point = CGPointMake(objectLocation.x + (COLLISION_CELL_WIDTH * xIndex),
                                            objectLocation.y + (COLLISION_CELL_HEIGHT * yIndex));
                [manager setPathNodeIsOpen:NO atLocation:point];
            }
        }
	}
	return self;
}

- (BOOL)attackedByEnemy:(TouchableObject *)enemy withDamage:(int)damage {
    [self blinkSelectionCircle];
    return [super attackedByEnemy:enemy withDamage:damage];
}

- (void)objectEnteredEffectRadius:(TouchableObject*)other {
	// For mining ships, turn in brogguts
	if (objectAlliance == other.objectAlliance) {
		if ([other isKindOfClass:[CraftObject class]]) {
			CraftObject* otherCraft = (CraftObject*)other;
			[otherCraft cashInBrogguts];
		}
	}
}

- (void)updateObjectLogicWithDelta:(float)aDelta {
    [super updateObjectLogicWithDelta:aDelta];
    
    if (blinkCounter > 0.0f) {
        blinkCounter -= aDelta;
    }
    if (blinkCounter <= 0.0f) {
        blinkCounter = 0.0f;
    }
    
    if (rotationCounter < BASE_STATION_LIGHT_DELAY) {
        rotationCounter += aDelta;
    }
    if (rotationCounter >= BASE_STATION_LIGHT_DELAY) {
        rotationCounter = 0.0f;
        blinkCounter = BASE_STATION_LIGHT_BLINK;
        if (lightPositionCounter < 360.0f) {
            lightPositionCounter += BASE_STATION_LIGHT_MOVE_DEGREES;
        }
        if (lightPositionCounter >= 360.0f) {
            lightPositionCounter = 0.0f;
        }
    }
}

- (void)renderOverObjectWithScroll:(Vector2f)scroll {
    [super renderOverObjectWithScroll:scroll];
    if (blinkCounter > 0.0f) {
        if (objectAlliance == kAllianceFriendly) {
            [blinkingStructureLightImage setColor:Color4fMake(0.0f, 0.75f, 0.1f, blinkCounter / BASE_STATION_LIGHT_BLINK)]; 
        } else if (objectAlliance == kAllianceEnemy) {
            [blinkingStructureLightImage setColor:Color4fMake(1.0f, 0.0f, 0.0f, blinkCounter / BASE_STATION_LIGHT_BLINK)];
        }        
        
        float xPos1 = objectLocation.x + (BASE_STATION_LIGHT_OUTER_DISTANCE * cosf(DEGREES_TO_RADIANS(lightPositionCounter)));
        float yPos1 = objectLocation.y + (BASE_STATION_LIGHT_OUTER_DISTANCE * sinf(DEGREES_TO_RADIANS(lightPositionCounter)));
        CGPoint point1 = CGPointMake(xPos1, yPos1);
        [blinkingStructureLightImage renderCenteredAtPoint:point1 withScrollVector:scroll];
        
        float xPos2 = objectLocation.x + (BASE_STATION_LIGHT_INNER_DISTANCE * cosf(DEGREES_TO_RADIANS(360.0f - lightPositionCounter)));
        float yPos2 = objectLocation.y + (BASE_STATION_LIGHT_INNER_DISTANCE * sinf(DEGREES_TO_RADIANS(360.0f - lightPositionCounter)));
        CGPoint point2 = CGPointMake(xPos2, yPos2);
        [blinkingStructureLightImage renderCenteredAtPoint:point2 withScrollVector:scroll];
    }
}

@end