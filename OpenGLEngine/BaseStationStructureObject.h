//
//  BaseStationStructure.h
//  OpenGLEngine
//
//  Created by James F Lockwood on 2/24/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StructureObject.h"

#define BASE_STATION_LIGHT_DELAY 0.02f
#define BASE_STATION_LIGHT_BLINK 0.1f
#define BASE_STATION_LIGHT_MOVE_DEGREES 5.0f
#define BASE_STATION_LIGHT_OUTER_DISTANCE 380.0f
#define BASE_STATION_LIGHT_INNER_DISTANCE 105.0f
#define BASE_STATION_WIDTH_CELLS 5
#define BASE_STATION_HEIGHT_CELLS 5

@interface BaseStationStructureObject : StructureObject {
    Image* blinkingStructureLightImage;
    float rotationCounter;
    float blinkCounter;
    float lightPositionCounter;
    
    BOOL hasBeenUpgraded;
}

- (id)initWithLocation:(CGPoint)location isTraveling:(BOOL)traveling;

@end
