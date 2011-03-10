//
//  OpenGLEngineAppDelegate.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 1/25/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "OpenGLEngineAppDelegate.h"
#import "EAGLView.h"
#import "GameController.h"

@implementation OpenGLEngineAppDelegate

@synthesize window;
@synthesize glView;

- (void)applicationEnded {
    [sharedGameController savePlayerProfile];
	[sharedGameController saveCurrentSceneWithFilename:@"SavedScene.plist"];
    [glView stopAnimation];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions   
{
	// Seed the random numbers!
	srandom(time(NULL));
	
	// Set the orientation!
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	// Get current orientation
	UIInterfaceOrientation orientation = [[UIDevice currentDevice] orientation];
	
	// If the device is already landscape, set it to the current
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		[[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
	} else {
		[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:NO];
	}
	
	sharedGameController = [GameController sharedGameController];
		
	// Creates and tries to authenticate the local player
	sharedGCSingleton = [GameCenterSingleton sharedGCSingleton];
	[window addSubview:sharedGCSingleton.view];
		
    [glView startAnimation];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	[self applicationEnded];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self applicationEnded];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [glView startAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	 [self applicationEnded];
}

- (void)dealloc
{
    [window release];
    [glView release];
    [super dealloc];
}

@end
