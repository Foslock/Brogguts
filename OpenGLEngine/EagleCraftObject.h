//
//  EagleCraftObject.h
//  OpenGLEngine
//
//  Created by James F Lockwood on 3/1/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CraftObject.h"

@interface EagleCraftObject : CraftObject {
    int healTimer;
    BOOL isHealingSelf;
}

- (id)initWithLocation:(CGPoint)location isTraveling:(BOOL)traveling;


@end
