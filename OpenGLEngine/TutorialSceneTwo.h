//
//  TutorialSceneTwo.h
//  OpenGLEngine
//
//  Created by James F Lockwood on 3/16/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TutorialScene.h"

@class TriggerObject;
@class CraftObject;
@class FingerObject;

@interface TutorialSceneTwo : TutorialScene {
    TriggerObject* antTrigger;
    CraftObject* myCraft;
    FingerObject* finger;
}

@end
