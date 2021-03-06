//
//  BlockStructure.h
//  OpenGLEngine
//
//  Created by James F Lockwood on 2/24/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StructureObject.h"

@interface BlockStructureObject : StructureObject {
    BOOL hasBeenAdded;
    BOOL hasBeenUpgraded;
}

- (id)initWithLocation:(CGPoint)location isTraveling:(BOOL)traveling;

@end
