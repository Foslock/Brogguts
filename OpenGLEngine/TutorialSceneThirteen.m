//
//  TutorialSceneThirteen.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 3/17/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "TutorialSceneThirteen.h"
#import "GameController.h"
#import "PlayerProfile.h"
#import "GameplayConstants.h"
#import "TriggerObject.h"
#import "CraftAndStructures.h"
#import "TextObject.h"
#import "GameCenterSingleton.h"

@implementation TutorialSceneThirteen

- (id)init {
    self = [super initWithTutorialIndex:12];
    if (self) {
        isAllowingOverview = YES;
        isShowingBroggutCount = YES;
        isShowingMetalCount = YES;
        isShowingSupplyCount = YES;
        isAllowingSidebar = YES;
        isAllowingCraft = YES;
        isAllowingStructures = YES;
        
        [helpText setObjectText:@"Metal is needed to build more advanced craft and structures. A refinery must be built to access the 'Refine Metal' menu. Build one and refine 200 brogguts into 20 Metal."];
        
        [fogManager setIsDrawingFogOnScene:YES];
        [fogManager setIsDrawingFogOnOverview:YES];
    }
    return self;
}

- (BOOL)checkObjective {
    int metalCount = [[sharedGameController currentProfile] metalCount];
    if (metalCount >= 20) {
        
        // Must include this in the last tutorial mission!
        [sharedGameCenterSingleton reportAchievementIdentifier:(NSString*)kAchievementIDCompletedTutorial percentComplete:100.0f];
        
        return YES;
    } else {
        return NO;
    }
}

@end
