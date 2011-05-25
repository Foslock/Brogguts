//
//  CampaignScene.h
//  OpenGLEngine
//
//  Created by James F Lockwood on 4/22/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BroggutScene.h"
#import "NotificationObject.h"

#define CAMPAIGN_SCENES_COUNT 15

@class StartMissionObject;

extern NSString* kCampaignSceneFileNames[CAMPAIGN_SCENES_COUNT + 1];

@interface CampaignScene : BroggutScene {
    int campaignIndex; 
    NSString* nextSceneName;
    BOOL isStartingMission;
    BOOL isObjectiveComplete;
    BOOL isAdvancingOrReset;
    StartMissionObject* startObject;
}

@property (nonatomic, assign) BOOL isStartingMission;

- (id)initWithCampaignIndex:(int)campIndex wasLoaded:(BOOL)loaded;
- (id)initWithLoaded:(BOOL)loaded;
- (BOOL)checkObjective;
- (BOOL)checkFailure;
- (BOOL)checkDefaultFailure;
- (void)advanceToNextLevel;
- (void)restartCurrentLevel;

@end