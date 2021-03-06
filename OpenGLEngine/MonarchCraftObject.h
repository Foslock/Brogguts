//
//  MonarchCraftObject.h
//  OpenGLEngine
//
//  Created by James F Lockwood on 2/24/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CraftObject.h"


@interface MonarchCraftObject : CraftObject {
    NSMutableArray* craftUnderAura;
    int craftLimit;
}

+ (int)protectionAmount;

- (id)initWithLocation:(CGPoint)location isTraveling:(BOOL)traveling;



@end
