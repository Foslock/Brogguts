//
//  CampaignSceneTwo.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 4/22/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "CampaignSceneTwo.h"
#import "GameController.h"
#import "PlayerProfile.h"
#import "StartMissionObject.h"

#define CAMPAIGN_TWO_BROGGUT_GOAL 5000 // 2500

@implementation CampaignSceneTwo

- (id)initWithLoaded:(BOOL)loaded {
    self = [super initWithCampaignIndex:1 wasLoaded:loaded];
    if (self) {
        [startObject setMissionTextTwo:[NSString stringWithFormat:@"- Collect %i Brogguts", CAMPAIGN_TWO_BROGGUT_GOAL]];
        if (!loaded) {
            {
                DialougeObject* dia = [[DialougeObject alloc] init];
                [dia setDialougeActivateTime:2.0f];
                [dia setDialougeImageIndex:0];
                [dia setDialougeText:@"This is a whole long bunch of text... and some more right here or so... maybe a few more lines?"];
                [sceneDialouges addObject:dia];
                [dia release];
            }
        }
        
    }
    return self;  
}

- (BOOL)checkObjective {
    int count = [[[GameController sharedGameController] currentProfile] broggutCount];
    if (count >= CAMPAIGN_TWO_BROGGUT_GOAL) {
        return YES;
    }
    return NO; // NO
}

- (BOOL)checkFailure {
    if ([self checkDefaultFailure]) {
        return YES;
    }
    return NO;
}

@end
