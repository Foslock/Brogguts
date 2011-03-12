//
//  StructureObject.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 2/12/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "StructureObject.h"
#import "Image.h"
#import "BroggutScene.h"
#import "CollisionManager.h"
#import "CraftObject.h"
#import "AntCraftObject.h"

@implementation StructureObject
@synthesize attributeHullCurrent;

- (void)initStructureWithID:(int)typeID {
	switch (typeID) {
		case kObjectStructureBaseStationID:
			attributeBroggutCost = kStructureBaseStationCostBrogguts;
			attributeMetalCost = kStructureBaseStationCostMetal;
			attributeHullCapacity = kStructureBaseStationHull;
			attributeHullCurrent = kStructureBaseStationHull;
			attributeMovingTime = kStructureBaseStationMovingTime;
			break;
		case kObjectStructureBlockID:
			attributeBroggutCost = kStructureBlockCostBrogguts;
			attributeMetalCost = kStructureBlockCostMetal;
			attributeHullCapacity = kStructureBlockHull;
			attributeHullCurrent = kStructureBlockHull;
			attributeMovingTime = kStructureBlockMovingTime;
			break;
		case kObjectStructureRefineryID:
			attributeBroggutCost = kStructureRefineryCostBrogguts;
			attributeMetalCost = kStructureRefineryCostMetal;
			attributeHullCapacity = kStructureRefineryHull;
			attributeHullCurrent = kStructureRefineryHull;
			attributeMovingTime = kStructureRefineryMovingTime;
			break;
		case kObjectStructureCraftUpgradesID:
			attributeBroggutCost = kStructureCraftUpgradesCostBrogguts;
			attributeMetalCost = kStructureCraftUpgradesCostMetal;
			attributeHullCapacity = kStructureCraftUpgradesHull;
			attributeHullCurrent = kStructureCraftUpgradesHull;
			attributeMovingTime = kStructureCraftUpgradesMovingTime;
			break;
		case kObjectStructureStructureUpgradesID:
			attributeBroggutCost = kStructureStructureUpgradesCostBrogguts;
			attributeMetalCost = kStructureStructureUpgradesCostMetal;
			attributeHullCapacity = kStructureStructureUpgradesHull;
			attributeHullCurrent = kStructureStructureUpgradesHull;
			attributeMovingTime = kStructureStructureUpgradesMovingTime;
			break;
		case kObjectStructureTurretID:
			attributeBroggutCost = kStructureTurretCostBrogguts;
			attributeMetalCost = kStructureTurretCostMetal;
			attributeHullCapacity = kStructureTurretHull;
			attributeHullCurrent = kStructureTurretHull;
			attributeMovingTime = kStructureTurretMovingTime;
			break;
		case kObjectStructureRadarID:
			attributeBroggutCost = kStructureRadarCostBrogguts;
			attributeMetalCost = kStructureRadarCostMetal;
			attributeHullCapacity = kStructureRadarHull;
			attributeHullCurrent = kStructureRadarHull;
			attributeMovingTime = kStructureRadarMovingTime;
			break;
		case kObjectStructureFixerID:
			attributeBroggutCost = kStructureFixerCostBrogguts;
			attributeMetalCost = kStructureFixerCostMetal;
			attributeHullCapacity = kStructureFixerHull;
			attributeHullCurrent = kStructureFixerHull;
			attributeMovingTime = kStructureFixerMovingTime;
			break;
		default:
			break;
	}
}

- (id)initWithTypeID:(int)typeID withLocation:(CGPoint)location isTraveling:(BOOL)traveling {
	Image* image;
	switch (typeID) {
		case kObjectStructureBaseStationID:
			image = [[Image alloc] initWithImageNamed:kObjectStructureBaseStationSprite filter:GL_LINEAR];
			break;
		case kObjectStructureBlockID:
			image = [[Image alloc] initWithImageNamed:kObjectStructureBlockSprite filter:GL_LINEAR];
			break;
		case kObjectStructureRefineryID:
			image = [[Image alloc] initWithImageNamed:kObjectStructureRefinerySprite filter:GL_LINEAR];
			break;
		case kObjectStructureCraftUpgradesID:
			image = [[Image alloc] initWithImageNamed:kObjectStructureCraftUpgradesSprite filter:GL_LINEAR];
			break;
		case kObjectStructureStructureUpgradesID:
			image = [[Image alloc] initWithImageNamed:kObjectStructureStructureUpgradesSprite filter:GL_LINEAR];
			break;
		case kObjectStructureTurretID:
			image = [[Image alloc] initWithImageNamed:kObjectStructureTurretSprite filter:GL_LINEAR];
			break;
		case kObjectStructureRadarID:
			image = [[Image alloc] initWithImageNamed:kObjectStructureRadarSprite filter:GL_LINEAR];
			break;
		case kObjectStructureFixerID:
			image = [[Image alloc] initWithImageNamed:kObjectStructureFixerSprite filter:GL_LINEAR];
			break;
		default:
			break;
	}
	self = [super initWithImage:image withLocation:location withObjectType:typeID];
	if (self) {
		staticObject = YES;
		isTouchable = YES;
		isCheckedForMultipleCollisions = YES;
		isCheckedForRadialEffect = YES;
		pathPointArray = nil;
		pathPointNumber = 0;
		isFollowingPath = NO;
		hasCurrentPathFinished = YES;
		creationEndLocation = location;
		// Initialize the structure
		[self initStructureWithID:typeID];
		if (traveling) {
			[self setIsTraveling:YES];
			NSArray* path = [NSArray arrayWithObject:[NSValue valueWithCGPoint:location]];
			[self followPath:path isLooped:NO];
		}
	}
	return self;
}

- (void)setCurrentHull:(int)newHull {
	if (newHull >= 0) {
		attributeHullCurrent = CLAMP(newHull, 0, attributeHullCapacity);
	}
}

- (void)drawHoverSelectionWithScroll:(Vector2f)scroll {
	if (isCurrentlyHoveredOver) {
		// Draw "selection circle"
		if (objectAlliance == kAllianceFriendly) {
			glColor4f(0.0f, 1.0f, 0.0f, 0.8f);
		} else {
			glColor4f(1.0f, 0.0f, 0.0f, 0.8f);
		}
		drawDashedCircle(self.boundingCircle, CIRCLE_SEGMENTS_COUNT, scroll);
	}
}

- (BOOL)attackedByEnemy:(TouchableObject *)enemy withDamage:(int)damage {
	[super attackedByEnemy:enemy withDamage:damage];
	attributeHullCurrent -= damage;
	if (attributeHullCurrent <= 0) {
		destroyNow = YES;
		return YES;
	}
	return NO;
}

- (void)updateObjectLogicWithDelta:(float)aDelta {
	if (attributeHullCurrent <= 0) {
		destroyNow = YES;
		return;
	}
	
	// Get the current point we should be following
	if (isFollowingPath && pathPointArray && !hasCurrentPathFinished) {
		NSValue* pointValue = [pathPointArray objectAtIndex:pathPointNumber];
		CGPoint moveTowardsPoint = [pointValue CGPointValue];
		// If the structure has reached the point...
		if (AreCGPointsEqual(objectLocation, moveTowardsPoint, 0.1f)) {
			pathPointNumber++;
		}
		if (pathPointNumber < [pathPointArray count]) {
			NSValue* pointValue = [pathPointArray objectAtIndex:pathPointNumber];
			moveTowardsPoint = [pointValue CGPointValue];
		} else {
			if (isPathLooped) {
				pathPointNumber = 0;
			} else {
				isFollowingPath = NO;
				hasCurrentPathFinished = YES;
				[self setMovingAIState:kMovingAIStateStill];
				if (isTraveling) {
					[self setIsTraveling:NO];
					[[self.currentScene collisionManager] setPathNodeIsOpen:NO atLocation:objectLocation];
				}
			}
		}
		[self moveTowardsLocation:moveTowardsPoint];
	} else {
		// Don't move, has reached target location
		objectVelocity = Vector2fZero;
	}
	
	[super updateObjectLogicWithDelta:aDelta];
}

- (void)renderCenteredAtPoint:(CGPoint)aPoint withScrollVector:(Vector2f)vector {
	[super renderCenteredAtPoint:aPoint withScrollVector:vector];
	enablePrimitiveDraw();
	[self drawHoverSelectionWithScroll:vector];
	disablePrimitiveDraw();
}

- (void)moveTowardsLocation:(CGPoint)location {
	float movingMagnitude = 1.0f / (float)attributeMovingTime;
	if (location.x > objectLocation.x) {
		if (fabs(location.x - objectLocation.x) > movingMagnitude)
			objectVelocity.x = movingMagnitude;
		else
			objectVelocity.x = location.x - objectLocation.x;
	}
	if (location.x < objectLocation.x) {
		if (fabs(location.x - objectLocation.x) > movingMagnitude)
			objectVelocity.x = - movingMagnitude;
		else
			objectVelocity.x = location.x - objectLocation.x;
	}
	if (location.y > objectLocation.y) {
		if (fabs(location.y - objectLocation.y) > movingMagnitude)
			objectVelocity.y = movingMagnitude;
		else
			objectVelocity.y = location.y - objectLocation.y;
	}
	if (location.y < objectLocation.y) {
		if (fabs(location.y - objectLocation.y) > movingMagnitude)
			objectVelocity.y = - movingMagnitude;
		else
			objectVelocity.y = location.y - objectLocation.y;
	}
}

- (void)followPath:(NSArray*)array isLooped:(BOOL)looped {
	if ([array count] == 0) {
		NSLog(@"Path contained no points!");
		return;
	}
	[pathPointArray autorelease];
	pathPointArray = [[NSMutableArray alloc] initWithArray:array];
	isFollowingPath = YES;
	pathPointNumber = 0;
	isPathLooped = looped;
	hasCurrentPathFinished = NO;
}

- (void)stopFollowingCurrentPath {
	isFollowingPath = NO;
	hasCurrentPathFinished = YES;
	[self setMovingAIState:kMovingAIStateStill];
}

- (void)resumeFollowingCurrentPath {
	if (pathPointArray && [pathPointArray count] != 0) {
		isFollowingPath = YES;
		hasCurrentPathFinished = NO;
		[self setMovingAIState:kMovingAIStateMoving];
	}
}

- (void)touchesBeganAtLocation:(CGPoint)location {
	// OVERRIDE ME
}

- (void)touchesMovedToLocation:(CGPoint)toLocation from:(CGPoint)fromLocation {
	// OVERRIDE ME
}

- (void)touchesEndedAtLocation:(CGPoint)location {
	// OVERRIDE ME
}

- (void)touchesDoubleTappedAtLocation:(CGPoint)location {
	// OVERRIDE ME
	NSLog(@"Object (%i) was double tapped!", uniqueObjectID);
}

@end