//
//  EndMissionObject.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 4/28/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "EndMissionObject.h"
#import "TextObject.h"
#import "TiledButtonObject.h"
#import "BroggutScene.h"
#import "ImageRenderSingleton.h"
#import "GameController.h"
#import "CampaignScene.h"
#import "GameplayConstants.h"
#import "BitmapFont.h"
#import "PlayerProfile.h"

@implementation EndMissionObject
@synthesize rect, wasSuccessfulMission;

- (id)init {
    self = [super initWithImage:nil withLocation:[currentScene middleOfVisibleScreen] withObjectType:kObjectEndMissionObjectID];
    if (self) {
        isCheckedForCollisions = NO;
        didAppear = NO;
        broggutsLeft = 0;
        broggutsEarned = 0;
        totalCount = 0;
        isTouchable = YES;
        wasSuccessfulMission = NO;
        CGPoint center = CGPointMake(kPadScreenLandscapeWidth / 2, kPadScreenLandscapeHeight / 2);
        CGRect temprect = CGRectMake(0, 0, kPadScreenLandscapeWidth, kPadScreenLandscapeHeight);
        rect = CGRectInset(temprect,
                           (kPadScreenLandscapeWidth - END_MISSION_BACKGROUND_WIDTH) / 2,
                           (kPadScreenLandscapeHeight - END_MISSION_BACKGROUND_HEIGHT) / 2);
        CGRect buttonRect = CGRectMake(rect.origin.x + END_MISSION_BUTTON_INSET,
                                       rect.origin.y + END_MISSION_BUTTON_INSET,
                                       END_MISSION_BUTTON_WIDTH,
                                       END_MISSION_BUTTON_HEIGHT);
        background = [[TiledButtonObject alloc] initWithRect:rect];
        [background setColor:Color4fMake(0.8f, 0.8f, 0.8f, 1.0f)];
        [background setIsPushable:NO];
        menuButton = [[TiledButtonObject alloc] initWithRect:buttonRect];
        CGRect confirmRect = CGRectOffset(buttonRect, END_MISSION_BACKGROUND_WIDTH - END_MISSION_BUTTON_WIDTH - (END_MISSION_BUTTON_INSET*2), 0);
        confirmButton = [[TiledButtonObject alloc] initWithRect:confirmRect];
        CGPoint textPoint = CGPointMake(center.x, center.y + 150);
        headerText = [[TextObject alloc] initWithFontID:kFontBlairID Text:@"TEXT" withLocation:textPoint withDuration:-1.0f];
        textPoint = CGPointMake(center.x - (END_MISSION_BACKGROUND_WIDTH / 4), center.y + 80);
        broggutsLeftLabel = [[TextObject alloc] initWithFontID:kFontBlairID Text:@"Brogguts Left: " withLocation:textPoint withDuration:-1.0f];
        textPoint = CGPointMake(center.x - (END_MISSION_BACKGROUND_WIDTH / 4), center.y + 30);
        broggutsEarnedLabel = [[TextObject alloc] initWithFontID:kFontBlairID Text:@"Brogguts Earned: " withLocation:textPoint withDuration:-1.0f];
        textPoint = CGPointMake(center.x - (END_MISSION_BACKGROUND_WIDTH / 4), center.y - 60);
        broggutsTotalLabel = [[TextObject alloc] initWithFontID:kFontBlairID Text:@"BaseCamp Brogguts: " withLocation:textPoint withDuration:-1.0f];
        textPoint = CGPointMake(center.x + (END_MISSION_BACKGROUND_WIDTH / 4), center.y + 80);
        broggutsLeftNumber = [[TextObject alloc] initWithFontID:kFontBlairID Text:@"0" withLocation:textPoint withDuration:-1.0f];
        [broggutsLeftNumber setFontColor:Color4fMake(0.8f, 1.0f, 1.0f, 1.0f)];
        textPoint = CGPointMake(center.x + (END_MISSION_BACKGROUND_WIDTH / 4), center.y + 30);
        broggutsEarnedNumber = [[TextObject alloc] initWithFontID:kFontBlairID Text:@"+0" withLocation:textPoint withDuration:-1.0f];
        [broggutsEarnedNumber setFontColor:Color4fMake(0.8f, 0.8f, 1.0f, 1.0f)];
        textPoint = CGPointMake(center.x + (END_MISSION_BACKGROUND_WIDTH / 4), center.y - 60);
        broggutsTotalNumber = [[TextObject alloc] initWithFontID:kFontBlairID Text:@"0" withLocation:textPoint withDuration:-1.0f];
        [broggutsTotalNumber setFontColor:Color4fMake(1.0f, 1.0f, 0.0f, 1.0f)];
        buttonArray = [[NSMutableArray alloc] initWithCapacity:10];
        textArray = [[NSMutableArray alloc] initWithCapacity:10];
        [buttonArray addObject:background];
        [buttonArray addObject:menuButton];
        [buttonArray addObject:confirmButton];
        [textArray addObject:headerText];
        [textArray addObject:broggutsLeftLabel];
        [textArray addObject:broggutsEarnedLabel];
        [textArray addObject:broggutsTotalLabel];
        [textArray addObject:broggutsLeftNumber];
        [textArray addObject:broggutsEarnedNumber];
        [textArray addObject:broggutsTotalNumber];
        for (TextObject* text in textArray) {
            [text setScrollWithBounds:NO];
            [text setRenderLayer:kLayerHUDTopLayer];
        }
        [background setRenderLayer:kLayerHUDBottomLayer];
        [menuButton setRenderLayer:kLayerHUDMiddleLayer];
        [confirmButton setRenderLayer:kLayerHUDMiddleLayer];
        
        [background release];
        [menuButton release];
        [confirmButton release];
        [headerText release];
        [broggutsLeftLabel release];
        [broggutsEarnedLabel release];
        [broggutsTotalLabel release];
        [broggutsLeftNumber release];
        [broggutsEarnedNumber release];
        [broggutsTotalNumber release];
    }
    return self;
}

- (void)endMissionDidAppear {
    if (!didAppear) {
        didAppear = YES;
        broggutsLeft = [[[GameController sharedGameController] currentProfile] broggutCount];
        broggutsEarned = [[[GameController sharedGameController] currentProfile] broggutCount] * PERCENT_BROGGUTS_CREDITED_FOR_SKIRMISH;
        NSString* broggutsLeftText = [NSString stringWithFormat:@"%i x %d%%", broggutsLeft, (int)(PERCENT_BROGGUTS_CREDITED_FOR_SKIRMISH*100.0f)];
        NSString* broggutsEarnedText = [NSString stringWithFormat:@"+%i",broggutsEarned];
        [broggutsLeftNumber setObjectText:broggutsLeftText];
        [broggutsEarnedNumber setObjectText:broggutsEarnedText];
        totalCounter = [[[GameController sharedGameController] currentProfile] baseCampBroggutCount];
    }
}

- (void)renderCenteredAtPoint:(CGPoint)aPoint withScrollVector:(Vector2f)vector {
    CGPoint center = CGPointMake(kPadScreenLandscapeWidth / 2, kPadScreenLandscapeHeight / 2);
    [super renderCenteredAtPoint:center withScrollVector:Vector2fZero];
    for (TiledButtonObject* object in buttonArray) {
        [object renderCenteredAtPoint:object.objectLocation withScrollVector:Vector2fZero];
    }
    
    BitmapFont* font = [[[self currentScene] fontArray] objectAtIndex:kFontGothicID];
    for (TextObject* text in textArray) {
        [text renderWithFont:font withScrollVector:Vector2fZero centered:YES];
    }
    
    // Render button text
    BitmapFont* buttonfont = [[[self currentScene] fontArray] objectAtIndex:kFontBlairID];
    [buttonfont renderStringJustifiedInFrame:[menuButton drawRect] justification:BitmapFontJustification_MiddleCentered text:@"Menu" onLayer:kLayerHUDTopLayer];
    if (wasSuccessfulMission) {
        [buttonfont renderStringJustifiedInFrame:[confirmButton drawRect] justification:BitmapFontJustification_MiddleCentered text:@"Next" onLayer:kLayerHUDTopLayer];
    } else {
        [buttonfont renderStringJustifiedInFrame:[confirmButton drawRect] justification:BitmapFontJustification_MiddleCentered text:@"Restart" onLayer:kLayerHUDTopLayer];
    }
}

- (void)updateObjectLogicWithDelta:(float)aDelta {
    [super updateObjectLogicWithDelta:aDelta];
    if (wasSuccessfulMission) {
        [headerText setObjectText:@"Mission Successful!"];
        [headerText setFontColor:Color4fMake(0.0f, 1.0f, 0.2f, 1.0f)];
    } else {
        [headerText setObjectText:@"Mission Failed!"];
        [headerText setFontColor:Color4fMake(1.0f, 0.0f, 0.2f, 1.0f)];
    }
    if (totalCount == 0) {
        totalCount = [[[GameController sharedGameController] currentProfile] baseCampBroggutCount];
    }
    if (totalCounter < totalCount) {
        totalCounter += 1;
    }
    NSString* broggutsText = [NSString stringWithFormat:@"%i",totalCounter];
    [broggutsTotalNumber setObjectText:broggutsText];
    
    if ([confirmButton wasJustReleased]) {
        BroggutScene* scene = [self currentScene];
        if (scene.sceneType == kSceneTypeCampaign) {
            if (wasSuccessfulMission)
                [(CampaignScene*)scene advanceToNextLevel];
            else
                [(CampaignScene*)scene restartCurrentLevel];
        }
        if (scene.sceneType == kSceneTypeBaseCamp) {
            [[GameController sharedGameController] createInitialBaseCampLevel];
        }
    } else if ([menuButton wasJustReleased]) {
        // Do update stuff with out the prompt
        if ([[self currentScene] isKindOfClass:[CampaignScene class]]) {
            CampaignScene* campaignScene = (CampaignScene*)[self currentScene];
            int currentExperience = [[[GameController sharedGameController] currentProfile] playerExperience];
            if (campaignScene.campaignIndex + 1 >= currentExperience) {
                [[[GameController sharedGameController] currentProfile] setPlayerExperience:campaignScene.campaignIndex + 1];
                [[[GameController sharedGameController] currentProfile] updateSpaceYearUnlocks];
            }
        }
        
        [[GameController sharedGameController] returnToMainMenuWithSave:NO];
    }
    for (TiledButtonObject* object in buttonArray) {
        [object updateObjectLogicWithDelta:aDelta];
    }
    for (TextObject* text in textArray) {
        [text updateObjectLogicWithDelta:aDelta];
    }
}

- (void)touchesBeganAtLocation:(CGPoint)location {
    [super touchesBeganAtLocation:location];
    [menuButton touchesBeganAtLocation:location];
    [confirmButton touchesBeganAtLocation:location];
    totalCounter = totalCount;
}

- (void)touchesMovedToLocation:(CGPoint)toLocation from:(CGPoint)fromLocation {
    [super touchesMovedToLocation:toLocation from:fromLocation];
    [menuButton touchesMovedToLocation:toLocation from:fromLocation];
    [confirmButton touchesMovedToLocation:toLocation from:fromLocation];
}

- (void)touchesEndedAtLocation:(CGPoint)location {
    [super touchesEndedAtLocation:location];
    [menuButton touchesEndedAtLocation:location];
    [confirmButton touchesEndedAtLocation:location];
}


- (void)dealloc
{
    [textArray release];
    [buttonArray release];
    [super dealloc];
}

@end
