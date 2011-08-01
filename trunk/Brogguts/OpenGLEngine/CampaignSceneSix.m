//
//  CampaignSceneSix.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 5/2/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "CampaignSceneSix.h"
#import "GameController.h"
#import "PlayerProfile.h"
#import "SpawnerObject.h"
#import "StartMissionObject.h"
#import "TextObject.h"

#define CAMPAIGN_SIX_WAVE_ONE_TIME 8.0f
#define CAMPAIGN_SIX_WAVE_TWO_TIME 13.0f

@implementation CampaignSceneSix

- (id)initWithLoaded:(BOOL)loaded {
    self = [super initWithCampaignIndex:5 wasLoaded:loaded];
    if (self) {
        [startObject setMissionTextOne:[NSString stringWithFormat:@"- Survive the first wave in %i minutes",(int)CAMPAIGN_SIX_WAVE_ONE_TIME]];
        [startObject setMissionTextTwo:[NSString stringWithFormat:@"- Survive the second wave at %i minutes",(int)CAMPAIGN_SIX_WAVE_TWO_TIME]];
        [startObject setMissionTextThree:@"- Destroy all enemy craft in both waves"];
        if (!loaded) {
            SpawnerObject* spawnerOne = [[SpawnerObject alloc] initWithLocation:CGPointMake(0.0f, fullMapBounds.size.height) objectID:kObjectCraftAntID withDuration:0.1f withCount:10];
            [spawnerOne addObjectWithID:kObjectCraftBeetleID withCount:2];
            [spawnerOne pauseSpawnerForDuration:(CAMPAIGN_SIX_WAVE_TWO_TIME * 60.0f) + 1.0f];
            [spawnerOne setSendingLocation:homeBaseLocation];
            [spawnerOne setSendingLocationVariance:128.0f];
            [spawnerOne setStartingLocationVariance:128.0f];
            [self addSpawner:spawnerOne];
            [spawnerOne release];
            
            SpawnerObject* spawnerTwo = [[SpawnerObject alloc] initWithLocation:CGPointMake(fullMapBounds.size.width, fullMapBounds.size.height) objectID:kObjectCraftAntID withDuration:0.1f withCount:8];
            [spawnerTwo addObjectWithID:kObjectCraftBeetleID withCount:2];
            [spawnerTwo pauseSpawnerForDuration:(CAMPAIGN_SIX_WAVE_ONE_TIME * 60.0f) + 1.0f];
            [spawnerTwo setSendingLocation:homeBaseLocation];
            [spawnerTwo setSendingLocationVariance:128.0f];
            [spawnerTwo setStartingLocationVariance:128.0f];
            [self addSpawner:spawnerTwo];
            [spawnerTwo release];
            
            SpawnerObject* spawnerThree = [[SpawnerObject alloc] initWithLocation:CGPointMake(fullMapBounds.size.width, 0.0f) objectID:kObjectCraftAntID withDuration:0.1f withCount:8];
            [spawnerThree addObjectWithID:kObjectCraftBeetleID withCount:2];
            [spawnerThree pauseSpawnerForDuration:(CAMPAIGN_SIX_WAVE_ONE_TIME * 60.0f) + 1.0f];
            [spawnerThree setSendingLocation:homeBaseLocation];
            [spawnerThree setSendingLocationVariance:128.0f];
            [spawnerThree setStartingLocationVariance:128.0f];
            [self addSpawner:spawnerThree];
            [spawnerThree release];
            
            SpawnerObject* spawnerFour = [[SpawnerObject alloc] initWithLocation:CGPointMake(0.0f, 0.0f) objectID:kObjectCraftAntID withDuration:0.1f withCount:8];
            [spawnerFour addObjectWithID:kObjectCraftBeetleID withCount:2];
            [spawnerFour pauseSpawnerForDuration:(CAMPAIGN_SIX_WAVE_TWO_TIME * 60.0f) + 1.0f];
            [spawnerFour setSendingLocation:homeBaseLocation];
            [spawnerFour setSendingLocationVariance:128.0f];
            [spawnerFour setStartingLocationVariance:128.0f];
            [self addSpawner:spawnerFour];
            [spawnerFour release];
        }
    }
    return self;
}

- (void)updateSceneWithDelta:(float)aDelta {
    [super updateSceneWithDelta:aDelta];
    if (isStartingMission || isMissionPaused) {
        return;
    }
    
    int minutes = 0;
    int seconds = 0;
    
    if (![[self spawnerWithID:1] isDoneSpawning]) {
        minutes = [[self spawnerWithID:1] pauseTimeLeft] / 60.0f;
        seconds = [[self spawnerWithID:1] pauseTimeLeft] - (60.0f * minutes);
    } else {
        minutes = [[self spawnerWithID:0] pauseTimeLeft] / 60.0f;
        seconds = [[self spawnerWithID:0] pauseTimeLeft] - (60.0f * minutes);
    }
    
    NSString* countdown;
    
    if (seconds >= 10) {
        countdown = [NSString stringWithFormat:@"Wave: %i:%i", minutes, seconds];
    } else {
        countdown = [NSString stringWithFormat:@"Wave: %i:0%i", minutes, seconds];
    }
    
    if (minutes != 0 || seconds != 0) {
        [countdownTimer setObjectText:countdown];
    } else {
        [countdownTimer setObjectText:@""];
    }
    
    [self updateSpawnersWithDelta:aDelta];
}

- (BOOL)checkObjective {
    int enemyShipCount = [self numberOfEnemyShips];
    if ([[self spawnerWithID:0] isDoneSpawning] && [[self spawnerWithID:1] isDoneSpawning] && 
        [[self spawnerWithID:2] isDoneSpawning] && [[self spawnerWithID:3] isDoneSpawning] &&
        enemyShipCount == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)checkFailure {
    if ([self checkDefaultFailure]) {
        return YES;
    }
    if (numberOfCurrentStructures <= 0) {
        return YES;
    }
    return NO;
}

@end