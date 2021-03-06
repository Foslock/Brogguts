//
//  ExplosionObject.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 4/18/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "ExplosionObject.h"
#import "AnimatedImage.h"
#import "Image.h"
#import "ImageRenderSingleton.h"
#import "ParticleSingleton.h"
#import "BroggutScene.h"
#import "SoundSingleton.h"

#define EXPLOSION_RING_GROWTH_RATE 1.05f
#define EXPLOSION_RING_FADE_RATE 0.05f

@implementation ExplosionObject

- (void)dealloc {
    [ringImage release];
    [animatedImage release];
    [super dealloc];
}

- (id)initWithLocation:(CGPoint)location withSize:(int)size {
    self = [super initWithImage:nil withLocation:location withObjectType:kObjectExplosionObjectID];
    if (self) {
        isCheckedForCollisions = NO;
        isCheckedForMultipleCollisions = NO;
        isRenderedInOverview = NO;
        float distance = 128.0f;
        switch (size) {
            case kExplosionSizeSmall: {
                animatedImage = [[AnimatedImage alloc] initWithFileName:kObjectExplosionSmallSprite withSubImageCount:8];
                for (int i = 0; i < 3; i++) {
                    float randX = RANDOM_MINUS_1_TO_1() * distance;
                    float randY = RANDOM_MINUS_1_TO_1() * distance;
                    CGPoint randPoint = CGPointMake(objectLocation.x + randX, objectLocation.y + randY);
                    [[ParticleSingleton sharedParticleSingleton] createParticles:4 withType:kParticleTypeSpark atLocation:randPoint];
                }
            }
                break;
            case kExplosionSizeMedium: {
                animatedImage = [[AnimatedImage alloc] initWithFileName:kObjectExplosionSmallSprite withSubImageCount:8];
                [animatedImage setScale:Scale2fMake(1.5f, 1.5f)];
                for (int i = 0; i < 3; i++) {
                    float randX = RANDOM_MINUS_1_TO_1() * distance;
                    float randY = RANDOM_MINUS_1_TO_1() * distance;
                    CGPoint randPoint = CGPointMake(objectLocation.x + randX, objectLocation.y + randY);
                    [[ParticleSingleton sharedParticleSingleton] createParticles:4 withType:kParticleTypeSpark atLocation:randPoint];
                }
            }
                break;
            case kExplosionSizeLarge: {
                animatedImage = [[AnimatedImage alloc] initWithFileName:kObjectExplosionLargeSprite withSubImageCount:8];
                [[ParticleSingleton sharedParticleSingleton] createParticles:40 withType:kParticleTypeSpark atLocation:objectLocation];
                for (int i = 0; i < 3; i++) {
                    float randX = RANDOM_MINUS_1_TO_1() * distance;
                    float randY = RANDOM_MINUS_1_TO_1() * distance;
                    CGPoint randPoint = CGPointMake(objectLocation.x + randX, objectLocation.y + randY);
                    [[ParticleSingleton sharedParticleSingleton] createParticles:4 withType:kParticleTypeSpark atLocation:randPoint];
                }
            }
                break;
            default:
                break;
        }
        self.objectRotation = RANDOM_0_TO_1() * 360.0f;
        [animatedImage setAnimationSpeed:0.15f + (RANDOM_0_TO_1() * 0.05f)];
        [animatedImage setRenderLayer:kLayerBottomLayer];
        
        ringImage = [[Image alloc] initWithImageNamed:kObjectExplosionRingSprite filter:GL_LINEAR];
        [ringImage setRenderLayer:kLayerBottomLayer];
        
        float distanceFromCenter = GetDistanceBetweenPoints(objectLocation, [[self currentScene] middleOfVisibleScreen]);
        if (distanceFromCenter < kPadScreenLandscapeWidth) {
            [[self currentScene] startShakingScreenWithMagnitude:10.0f];
        }
        
        [[SoundSingleton sharedSoundSingleton] playSoundWithKey:kSoundFileNames[kSoundFileExplosionSound] location:objectLocation];
    }
    return self;
}

- (void)updateObjectLogicWithDelta:(float)aDelta {
    [super updateObjectLogicWithDelta:aDelta];
    
    ringImage.scale = Scale2fMake(ringImage.scale.x * EXPLOSION_RING_GROWTH_RATE,
                                  ringImage.scale.y * EXPLOSION_RING_GROWTH_RATE);
    ringImage.color = Color4fMake(1.0f, 1.0f, 0.4f,
                                  CLAMP(ringImage.color.alpha-EXPLOSION_RING_FADE_RATE, 0, 0.75f));
    
    
    if ([animatedImage isAnimationComplete]) {
        self.destroyNow = YES;
    }
    
    [animatedImage updateAnimatedImageWithDelta:aDelta];
}

- (void)renderCenteredAtPoint:(CGPoint)aPoint withScrollVector:(Vector2f)vector {
    [animatedImage renderCurrentSubImageAtPoint:CGPointMake(objectLocation.x - vector.x, objectLocation.y - vector.y)
                                      withScale:Scale2fMake(1.0f, 1.0f)
                                   withRotation:objectRotation];
    [ringImage renderCenteredAtPoint:CGPointMake(objectLocation.x - vector.x, objectLocation.y - vector.y)];
}


@end
