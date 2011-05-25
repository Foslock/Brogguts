//
//  GameController.m
//  OpenGLEngine
//
//  Created by James F Lockwood on 2/1/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import "GameController.h"
#import "SoundSingleton.h"
#import "OpenGLEngineAppDelegate.h"
#import "BroggutScene.h"
#import "BaseCampScene.h"
#import "CollisionManager.h"
#import "PlayerProfile.h"
#import "ParticleSingleton.h"
#import "StructureObject.h"
#import "CraftObject.h"
#import "CraftAndStructures.h"
#import "TextObject.h"
#import "BitmapFont.h"
#import "TutorialFiles.h"
#import "GameCenterSingleton.h"
#import "BroggupediaViewController.h"

NSString* kBaseCampFileName = @"BaseCamp.plist";
NSString* kSavedCampaignFileName = @"SavedCampaignList.plist";
NSString* kSavedSkirmishFileName = @"SavedSkirmishList.plist";
NSString* kNewMapScenesFileName = @"NewMapScenesList.plist";

BOOL doesSceneShowGrid = YES;

#pragma mark -
#pragma mark Private interface

@interface GameController (Private) 
// Initializes OpenGL
- (void)initGameController;

@end

static GameController* sharedGameController = nil;

@implementation GameController

@synthesize currentProfile;
@synthesize currentScene, justMadeScene, transitionName;
@synthesize gameScenes;
@synthesize eaglView;
@synthesize interfaceOrientation;
@synthesize isFadingSceneIn, isFadingSceneOut;

#pragma mark -
#pragma mark Singleton implementation

+ (GameController *)sharedGameController
{
	@synchronized (self) {
		if (sharedGameController == nil) {
			[[self alloc] init];
		}
	}
	
	return sharedGameController;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self) {
		if (sharedGameController == nil) {
			sharedGameController = [super allocWithZone:zone];
			return sharedGameController;
		}
	}
	
	return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)retain
{
	return self;
}

- (void)release
{
	// do nothing
}

- (id)autorelease
{
	return self;
}

- (NSUInteger)retainCount
{
	return NSUIntegerMax; // This is sooo not zero
}


#pragma mark -
#pragma mark Public implementation

- (void)dealloc {
	[[SoundSingleton sharedSoundSingleton] shutdownSoundManager];
	[currentScene release];
    [gameScenes release];
	[transitionName release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if(self != nil) {
		// Initialize the game
        [self initGameController];
    }
    return self;
}

- (void)presentBroggupedia {
    if (!isShowingBroggupediaInScene) {
        isShowingBroggupediaInScene = YES;
        BroggupediaViewController* object = [[BroggupediaViewController alloc] init];
        OpenGLEngineAppDelegate* delegate = [[UIApplication sharedApplication] delegate];
        [[delegate window] bringSubviewToFront:[delegate mainMenuController].view];
        if (isAlreadyInScene)
            [[delegate mainMenuController] presentModalViewController:object animated:NO];
        else
            [[delegate mainMenuController] presentModalViewController:object animated:YES];
        [object release];
    }
}

- (void)dismissBroggupedia {
    if (isShowingBroggupediaInScene) {
        isShowingBroggupediaInScene = NO;
        OpenGLEngineAppDelegate* delegate = [[UIApplication sharedApplication] delegate];
        [[delegate mainMenuController] dismissModalViewControllerAnimated:YES];
        if (isAlreadyInScene)
            [[delegate window] bringSubviewToFront:[delegate glView]];
    }
}

- (void)loadPlayerProfile {
	NSLog(@"INFO - GameController: Loading previous player profile.");
	NSString* path = [self documentsPathWithFilename:@"playerprofile.data"];
	NSDictionary* rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];    
	[self setCurrentProfile:[rootObject valueForKey:@"Profile"]];
	if (!currentProfile) {
		NSLog(@"INFO - GameController: No previous player profile, creating a brand new profile.");
		currentProfile = [[PlayerProfile alloc] init];
	}
    [currentProfile updateSpaceYearUnlocks];
}

- (void)savePlayerProfile {
	NSLog(@"INFO - GameController: Saving current player profile.");
	NSString* path = [self documentsPathWithFilename:@"playerprofile.data"];
	NSMutableDictionary* rootObject = [NSMutableDictionary dictionary];
	[rootObject setValue:currentProfile forKey:@"Profile"];
	if (![NSKeyedArchiver archiveRootObject:rootObject toFile:path]){
		NSLog(@"INFO - GameController: Saving failed.");
	}
}

- (NSString*)documentsPathWithFilename:(NSString*)filename {
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
	NSString* filePath = [documentsDirectory stringByAppendingPathComponent:filename];
	return filePath;
}

- (BOOL)doesFilenameExistInDocuments:(NSString*)filename {
    NSString* filePath = [self documentsPathWithFilename:filename];
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
	if (fileExists) {
		return YES;
	} else {
        return NO;
    }
}

- (void)insertCGPoint:(CGPoint)point intoArray:(NSMutableArray*)array atIndex:(int)index {
	NSMutableArray* newPointArray = [[NSMutableArray alloc] init];
	[newPointArray insertObject:[NSNumber numberWithFloat:point.x] atIndex:0];
	[newPointArray insertObject:[NSNumber numberWithFloat:point.y] atIndex:1];
	[array insertObject:newPointArray atIndex:index];
	[newPointArray release];
}

- (CGPoint)getCGPointFromArray:(NSArray*)array atIndex:(int)index {
	NSArray* pointArray = [array objectAtIndex:index];
	NSNumber* xNum = [pointArray objectAtIndex:0];
	NSNumber* yNum = [pointArray objectAtIndex:1];
	return CGPointMake([xNum floatValue], [yNum floatValue]);
}

- (void)placeInitialFilesInDocumentsFolder {
    NSString* oldFilePath = [[NSBundle mainBundle] pathForResource:@"NewMapScenesList" ofType:@"plist"];
    NSArray* tempMapPlist = [NSArray arrayWithContentsOfFile:oldFilePath];
    if (tempMapPlist) {
        for (NSString* mapName in tempMapPlist) {
            NSString* mapNamePath = [[NSBundle mainBundle] pathForResource:mapName ofType:@"plist"];
            NSArray* mapArray = [NSArray arrayWithContentsOfFile:mapNamePath];
            if (mapArray) {
                NSString* newFileName = [mapName stringByAppendingString:@".plist"];
                [mapArray writeToFile:[self documentsPathWithFilename:newFileName] atomically:YES];
            }
        }
        NSString* newFilePath = [self documentsPathWithFilename:kNewMapScenesFileName];
        [tempMapPlist writeToFile:newFilePath atomically:YES];  
    }
    
    if (![self doesFilenameExistInDocuments:kSavedSkirmishFileName]) {
        NSArray* newArray = [[NSArray alloc] init];
        NSString* path = [self documentsPathWithFilename:kSavedSkirmishFileName];
        [newArray writeToFile:path atomically:YES];
        [newArray release];
    }
    
    if (![self doesFilenameExistInDocuments:kSavedCampaignFileName]) {
        NSArray* newArray = [[NSArray alloc] init];
        NSString* path = [self documentsPathWithFilename:kSavedCampaignFileName];
        [newArray writeToFile:path atomically:YES];
        [newArray release];
    }
    
    if (![self doesFilenameExistInDocuments:kBaseCampFileName]) {
        // [self createInitialBaseCampLevel];
        NSString* campNamePath = [[NSBundle mainBundle] pathForResource:kBaseCampFileName ofType:@""];
        NSArray* campArray = [NSArray arrayWithContentsOfFile:campNamePath];
        [campArray writeToFile:[self documentsPathWithFilename:kBaseCampFileName] atomically:YES];
    }
    
    for (int i = 0; i < TUTORIAL_SCENES_COUNT; i++) {
        NSString* name = kTutorialSceneFileNames[i];
        NSString* fileName = [name stringByAppendingString:@".plist"];
        if (![self doesFilenameExistInDocuments:fileName]) {
            NSString* filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
            NSArray* newArray = [[NSArray alloc] initWithContentsOfFile:filePath];
            if (newArray) {
                NSString* newPath = [self documentsPathWithFilename:fileName];
                [newArray writeToFile:newPath atomically:YES];
                [newArray release];
            }
        }
    }
    
    for (int i = 0; i < CAMPAIGN_SCENES_COUNT; i++) {
        NSString* name = kCampaignSceneFileNames[i];
        NSString* fileName = [name stringByAppendingString:@".plist"];
        if (![self doesFilenameExistInDocuments:fileName]) {
            NSString* filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
            NSArray* newArray = [[NSArray alloc] initWithContentsOfFile:filePath];
            if (newArray) {
                NSString* newPath = [self documentsPathWithFilename:fileName];
                [newArray writeToFile:newPath atomically:YES];
                [newArray release];
            }
        }
    }
}

- (void)createBlankSceneWithWidthCells:(int)width withHeightCells:(int)height withName:(NSString*)name {
    NSString* sceneTitle = name;
	int thisSceneType = kSceneTypeSkirmish;
	int widthCells = width;
	int heightCells = height;
	int numberOfSmallBrogguts = 0;
	
	NSMutableArray* plistArray = [[NSMutableArray alloc] init];
	[plistArray insertObject:sceneTitle atIndex:kSceneStorageGlobalName];
	[plistArray insertObject:[NSNumber numberWithInt:thisSceneType] atIndex:kSceneStorageGlobalSceneType];
	[plistArray insertObject:[NSNumber numberWithInt:widthCells] atIndex:kSceneStorageGlobalWidthCells];
	[plistArray insertObject:[NSNumber numberWithInt:heightCells] atIndex:kSceneStorageGlobalHeightCells];
	[plistArray insertObject:[NSNumber numberWithInt:numberOfSmallBrogguts] atIndex:kSceneStorageGlobalSmallBrogguts];
    NSArray* tempArray = [[NSArray alloc] init];
    [plistArray insertObject:tempArray atIndex:kSceneStorageGlobalAIController];
    [tempArray release];
    
    NSMutableArray* broggutArray = [[NSMutableArray alloc] initWithCapacity:widthCells * heightCells];
	for (int j = 0; j < heightCells; j++) {
		for (int i = 0; i < widthCells; i++) {
			int straightIndex = i + (j * widthCells);
			NSMutableArray* thisBroggutInfo = [[NSMutableArray alloc] init];
			NSNumber* broggutValue;
			NSNumber* broggutAge;
            broggutValue = [NSNumber numberWithInt:-1];
            broggutAge = [NSNumber numberWithInt:-1];
			[thisBroggutInfo insertObject:broggutValue atIndex:0];
			[thisBroggutInfo insertObject:broggutAge atIndex:1];
			[broggutArray insertObject:thisBroggutInfo atIndex:straightIndex];
			[thisBroggutInfo release];
		}
	}
	[plistArray insertObject:broggutArray atIndex:kSceneStorageGlobalMediumBroggutArray];
	[broggutArray release];
    
    NSMutableArray* finalObjectArray = [[NSMutableArray alloc] init];
    [plistArray insertObject:finalObjectArray atIndex:kSceneStorageGlobalObjectArray];
    [finalObjectArray release];
    NSString* fileName = [name stringByAppendingString:@".plist"];
	NSString* filePath = [self documentsPathWithFilename:fileName];
	if (![plistArray writeToFile:filePath atomically:YES]) {
		NSLog(@"Cannot save the empty Scene!");
	}
	[plistArray release];
}

- (void)createInitialBaseCampLevel {
	NSString* sceneTitle = @"Base Camp";
	int sceneType = kSceneTypeBaseCamp;
	int widthCells = 32;
	int heightCells = 24;
	int numberOfSmallBrogguts = 500;
	
	NSMutableArray* plistArray = [[NSMutableArray alloc] init];
	[plistArray insertObject:sceneTitle atIndex:kSceneStorageGlobalName];
	[plistArray insertObject:[NSNumber numberWithInt:sceneType] atIndex:kSceneStorageGlobalSceneType];
	[plistArray insertObject:[NSNumber numberWithInt:widthCells] atIndex:kSceneStorageGlobalWidthCells];
	[plistArray insertObject:[NSNumber numberWithInt:heightCells] atIndex:kSceneStorageGlobalHeightCells];
	[plistArray insertObject:[NSNumber numberWithInt:numberOfSmallBrogguts] atIndex:kSceneStorageGlobalSmallBrogguts];
    NSArray* tempArray = [[NSArray alloc] init];
    [plistArray insertObject:tempArray atIndex:kSceneStorageGlobalAIController];
    [tempArray release];
	
	// Save all the other crap, medium brogguts first
	NSMutableArray* broggutArray = [[NSMutableArray alloc] initWithCapacity:widthCells * heightCells];
	for (int j = 0; j < heightCells; j++) {
		for (int i = 0; i < widthCells; i++) {
			int straightIndex = i + (j * widthCells);
			NSMutableArray* thisBroggutInfo = [[NSMutableArray alloc] init];
			NSNumber* broggutValue;
			NSNumber* broggutAge;
			if ( (i > 4 && i < 27) && ((i > 14 && i < 17) || (j > 10 && j < 13)) ) {
				broggutValue = [NSNumber numberWithInt:400];
				broggutAge = [NSNumber numberWithInt:kBroggutMediumAgeYoung];
			} else {
				broggutValue = [NSNumber numberWithInt:-1];
				broggutAge = [NSNumber numberWithInt:-1];
			}			
			[thisBroggutInfo insertObject:broggutValue atIndex:0];
			[thisBroggutInfo insertObject:broggutAge atIndex:1];
			[broggutArray insertObject:thisBroggutInfo atIndex:straightIndex];
			[thisBroggutInfo release];
		}
	}
	[plistArray insertObject:broggutArray atIndex:kSceneStorageGlobalMediumBroggutArray];
	[broggutArray release];
	
	// Save structures, namely the base stations
	NSMutableArray* finalObjectArray = [[NSMutableArray alloc] init];
	// Create the initial base station: 
    for (int i = 0; i < 2; i++) {
		NSMutableArray* thisStructureArray = [[NSMutableArray alloc] init];
		
		int objectTypeID = kObjectTypeStructure;
		int objectID = kObjectStructureBaseStationID;
		NSArray* objectCurrentPath = [[NSArray alloc] init]; // NIL for now
		int objectAlliance = kAllianceFriendly;
        if (i == 1) {
            objectAlliance = kAllianceEnemy;
        }
		float objectRotation = 0.0f;
		BOOL objectIsTraveling = NO;
		CGPoint objectEndLocation = CGPointMake(COLLISION_CELL_WIDTH / 2,
                                                COLLISION_CELL_HEIGHT / 2 + (COLLISION_CELL_HEIGHT * heightCells / 2));
        if (i == 1) {
            objectEndLocation = CGPointMake((COLLISION_CELL_WIDTH * widthCells) - COLLISION_CELL_WIDTH / 2,
                                            COLLISION_CELL_HEIGHT / 2 + (COLLISION_CELL_HEIGHT * heightCells / 2));
        }
		CGPoint objectCurrentLocation = objectEndLocation;
		int objectCurrentHull = -1; // Means full
		BOOL objectIsControlledShip = NO;
		BOOL objectIsMining = NO;
		CGPoint objectMiningLocation = CGPointZero;
		int objectCurrentCargo = 0;
		
		[thisStructureArray insertObject:[NSNumber numberWithInt:objectTypeID] atIndex:kSceneStorageIndexTypeID];
		[thisStructureArray insertObject:[NSNumber numberWithInt:objectID] atIndex:kSceneStorageIndexID];
		[thisStructureArray insertObject:objectCurrentPath atIndex:kSceneStorageIndexPath];
		[thisStructureArray insertObject:[NSNumber numberWithInt:objectAlliance] atIndex:kSceneStorageIndexAlliance];
		[thisStructureArray insertObject:[NSNumber numberWithFloat:objectRotation] atIndex:kSceneStorageIndexRotation];
		[thisStructureArray insertObject:[NSNumber numberWithBool:objectIsTraveling] atIndex:kSceneStorageIndexTraveling];
		[self insertCGPoint:objectEndLocation intoArray:thisStructureArray atIndex:kSceneStorageIndexEndLoc];
		[self insertCGPoint:objectCurrentLocation intoArray:thisStructureArray atIndex:kSceneStorageIndexCurrentLoc];
		[thisStructureArray insertObject:[NSNumber numberWithInt:objectCurrentHull] atIndex:kSceneStorageIndexHull];
		[thisStructureArray insertObject:[NSNumber numberWithBool:objectIsControlledShip] atIndex:kSceneStorageIndexControlledShip];
		[thisStructureArray insertObject:[NSNumber numberWithBool:objectIsMining] atIndex:kSceneStorageIndexMining];
		[self insertCGPoint:objectMiningLocation intoArray:thisStructureArray atIndex:kSceneStorageIndexMiningLoc];
		[thisStructureArray insertObject:[NSNumber numberWithInt:objectCurrentCargo] atIndex:kSceneStorageIndexCargo];
		if (objectID == kObjectStructureBaseStationID) {
			[finalObjectArray insertObject:thisStructureArray atIndex:0];
		} else {
			[finalObjectArray addObject:thisStructureArray];
		}
		[thisStructureArray release];
		[objectCurrentPath release];
	}
	
	// Create the initial ANT craft for the player: 
	for (int i = 0; i < 2; i++) {
		NSMutableArray* thisCraftArray = [[NSMutableArray alloc] init];
		
		int objectTypeID = kObjectTypeCraft;
		int objectID = kObjectCraftAntID;
		NSArray* objectCurrentPath = [[NSArray alloc] init]; // NIL for now
		int objectAlliance = kAllianceFriendly;
		if (i == 1) {
            objectAlliance = kAllianceEnemy;
        }
		float objectRotation = 0.0f;
		BOOL objectIsTraveling = NO;
		CGPoint objectEndLocation = CGPointMake((COLLISION_CELL_WIDTH / 2) * 5,
                                                COLLISION_CELL_HEIGHT / 2 + (COLLISION_CELL_HEIGHT * heightCells / 2));
        if (i == 1) {
            objectEndLocation = CGPointMake((COLLISION_CELL_WIDTH * widthCells) - ( (COLLISION_CELL_WIDTH / 2) * 5),
                                            COLLISION_CELL_HEIGHT / 2 + (COLLISION_CELL_HEIGHT * heightCells / 2));
        }
		CGPoint objectCurrentLocation = objectEndLocation;
		int objectCurrentHull = -1; // Means full
		BOOL objectIsControlledShip = YES;
        if (i == 1) {
            objectIsControlledShip = NO;
        }
		BOOL objectIsMining = NO;
		CGPoint objectMiningLocation = CGPointZero;
		int objectCurrentCargo = 0;
		
		[thisCraftArray insertObject:[NSNumber numberWithInt:objectTypeID] atIndex:kSceneStorageIndexTypeID];
		[thisCraftArray insertObject:[NSNumber numberWithInt:objectID] atIndex:kSceneStorageIndexID];
		[thisCraftArray insertObject:objectCurrentPath atIndex:kSceneStorageIndexPath];
		[thisCraftArray insertObject:[NSNumber numberWithInt:objectAlliance] atIndex:kSceneStorageIndexAlliance];
		[thisCraftArray insertObject:[NSNumber numberWithFloat:objectRotation] atIndex:kSceneStorageIndexRotation];
		[thisCraftArray insertObject:[NSNumber numberWithBool:objectIsTraveling] atIndex:kSceneStorageIndexTraveling];
		[self insertCGPoint:objectEndLocation intoArray:thisCraftArray atIndex:kSceneStorageIndexEndLoc];
		[self insertCGPoint:objectCurrentLocation intoArray:thisCraftArray atIndex:kSceneStorageIndexCurrentLoc];
		[thisCraftArray insertObject:[NSNumber numberWithInt:objectCurrentHull] atIndex:kSceneStorageIndexHull];
		[thisCraftArray insertObject:[NSNumber numberWithBool:objectIsControlledShip] atIndex:kSceneStorageIndexControlledShip];
		[thisCraftArray insertObject:[NSNumber numberWithBool:objectIsMining] atIndex:kSceneStorageIndexMining];
		[self insertCGPoint:objectMiningLocation intoArray:thisCraftArray atIndex:kSceneStorageIndexMiningLoc];
		[thisCraftArray insertObject:[NSNumber numberWithInt:objectCurrentCargo] atIndex:kSceneStorageIndexCargo];
		[finalObjectArray addObject:thisCraftArray];
		[thisCraftArray release];
		[objectCurrentPath release];
	}
	/*
     // Create a bunch of enemies to try to kill
     for (int i = 0; i < 100; i++) {
     for (int j = 0; j < 1; j++) {
     NSMutableArray* thisCraftArray = [[NSMutableArray alloc] init];
     
     int objectTypeID = kObjectTypeCraft;
     int objectID = kObjectCraftAntID;
     NSArray* objectCurrentPath = [[NSArray alloc] init]; // NIL for now
     int objectAlliance = kAllianceEnemy;
     float objectRotation = 360 * RANDOM_MINUS_1_TO_1();
     BOOL objectIsTraveling = NO;
     CGPoint objectEndLocation = CGPointMake((100 + j) * COLLISION_CELL_WIDTH / 2, (i + 5) * COLLISION_CELL_HEIGHT / 2);
     CGPoint objectCurrentLocation = objectEndLocation;
     int objectCurrentHull = -1; // Means full
     BOOL objectIsControlledShip = NO;
     BOOL objectIsMining = NO;
     CGPoint objectMiningLocation = CGPointZero;
     int objectCurrentCargo = 0;
     
     [thisCraftArray insertObject:[NSNumber numberWithInt:objectTypeID] atIndex:kSceneStorageIndexTypeID];
     [thisCraftArray insertObject:[NSNumber numberWithInt:objectID] atIndex:kSceneStorageIndexID];
     [thisCraftArray insertObject:objectCurrentPath atIndex:kSceneStorageIndexPath];
     [thisCraftArray insertObject:[NSNumber numberWithInt:objectAlliance] atIndex:kSceneStorageIndexAlliance];
     [thisCraftArray insertObject:[NSNumber numberWithFloat:objectRotation] atIndex:kSceneStorageIndexRotation];
     [thisCraftArray insertObject:[NSNumber numberWithBool:objectIsTraveling] atIndex:kSceneStorageIndexTraveling];
     [self insertCGPoint:objectEndLocation intoArray:thisCraftArray atIndex:kSceneStorageIndexEndLoc];
     [self insertCGPoint:objectCurrentLocation intoArray:thisCraftArray atIndex:kSceneStorageIndexCurrentLoc];
     [thisCraftArray insertObject:[NSNumber numberWithInt:objectCurrentHull] atIndex:kSceneStorageIndexHull];
     [thisCraftArray insertObject:[NSNumber numberWithBool:objectIsControlledShip] atIndex:kSceneStorageIndexControlledShip];
     [thisCraftArray insertObject:[NSNumber numberWithBool:objectIsMining] atIndex:kSceneStorageIndexMining];
     [self insertCGPoint:objectMiningLocation intoArray:thisCraftArray atIndex:kSceneStorageIndexMiningLoc];
     [thisCraftArray insertObject:[NSNumber numberWithInt:objectCurrentCargo] atIndex:kSceneStorageIndexCargo];
     [finalObjectArray addObject:thisCraftArray];
     [thisCraftArray release];
     [objectCurrentPath release];
     }
     }
     */
	[plistArray insertObject:finalObjectArray atIndex:kSceneStorageGlobalObjectArray];
    [finalObjectArray release];
	NSString* filePath = [self documentsPathWithFilename:kBaseCampFileName];
	if (![plistArray writeToFile:filePath atomically:YES]) {
		NSLog(@"Cannot save the Base Camp Scene!");
	}
	[plistArray release];
}

- (BOOL)saveCurrentSceneWithFilename:(NSString*)filename allowOverwrite:(BOOL)overwrite {
    if (!currentScene) {
        return NO;
    }
    if (currentScene.sceneType == kSceneTypeTutorial) {
        NSLog(@"Scene filename: %@, it is a tutorial level", filename);
        return NO;
    }
    if ([self doesFilenameExistInDocuments:filename] && !overwrite) {
        NSLog(@"Scene filename: %@, already exists", filename);
        return NO;
    }
	
	NSString* sceneTitle = currentScene.sceneName;
	int thisSceneType = currentScene.sceneType;
	int widthCells = currentScene.widthCells;
	int heightCells = currentScene.heightCells;
	int numberOfSmallBrogguts = currentScene.numberOfSmallBrogguts;
    
	NSMutableArray* plistArray = [[NSMutableArray alloc] init];
	[plistArray insertObject:sceneTitle atIndex:kSceneStorageGlobalName];
	[plistArray insertObject:[NSNumber numberWithInt:thisSceneType] atIndex:kSceneStorageGlobalSceneType];
	[plistArray insertObject:[NSNumber numberWithInt:widthCells] atIndex:kSceneStorageGlobalWidthCells];
	[plistArray insertObject:[NSNumber numberWithInt:heightCells] atIndex:kSceneStorageGlobalHeightCells];
	[plistArray insertObject:[NSNumber numberWithInt:numberOfSmallBrogguts] atIndex:kSceneStorageGlobalSmallBrogguts];
    NSArray* tempArray = [[NSArray alloc] init];
    [plistArray insertObject:tempArray atIndex:kSceneStorageGlobalAIController];
    [tempArray release];
	
	// Save all the other crap, medium brogguts first
	NSMutableArray* broggutArray = [[NSMutableArray alloc] initWithCapacity:widthCells * heightCells];
	for (int j = 0; j < heightCells; j++) {
		for (int i = 0; i < widthCells; i++) {
			float currentX = (i * COLLISION_CELL_WIDTH) + (COLLISION_CELL_WIDTH / 2);
			float currentY = (j * COLLISION_CELL_HEIGHT) + (COLLISION_CELL_HEIGHT / 2);
			CGPoint currentPoint = CGPointMake(currentX, currentY);
			int straightIndex = i + (j * widthCells);
			NSMutableArray* thisBroggutInfo = [[NSMutableArray alloc] init];
			MediumBroggut* broggut = [[currentScene collisionManager] broggutCellForLocation:currentPoint]; 
			NSNumber* broggutValue = [NSNumber numberWithInt:broggut->broggutValue];
			NSNumber* broggutAge = [NSNumber numberWithInt:broggut->broggutAge];
			[thisBroggutInfo insertObject:broggutValue atIndex:0];
			[thisBroggutInfo insertObject:broggutAge atIndex:1];
			[broggutArray insertObject:thisBroggutInfo atIndex:straightIndex];
			[thisBroggutInfo release];
		}
	}
	[plistArray insertObject:broggutArray atIndex:kSceneStorageGlobalMediumBroggutArray];
	[broggutArray release];
	
	// Save structures, namely the base stations
	NSMutableArray* finalObjectArray = [[NSMutableArray alloc] init];
	
	NSArray* currentObjectArray = [NSArray arrayWithArray:[currentScene touchableObjects]];
	for (int i = 0; i < [currentObjectArray count]; i++) {
		TouchableObject* object = [currentObjectArray objectAtIndex:i];
        if ([object destroyNow]) {
            continue;
        }
		if ([object isKindOfClass:[StructureObject class]]) {
			// It is a structure, so save it!
			NSMutableArray* thisStructureArray = [[NSMutableArray alloc] init];
			StructureObject* thisStructure = (StructureObject*)object;
			
			int objectTypeID = kObjectTypeStructure;
			int objectID = thisStructure.objectType;
			NSArray* objectCurrentPath = [[NSArray alloc] init]; // NIL for now
			int objectAlliance = thisStructure.objectAlliance;
			float objectRotation = thisStructure.objectRotation;
			BOOL objectIsTraveling = thisStructure.isTraveling;
			CGPoint objectEndLocation = thisStructure.objectLocation;
			CGPoint objectCurrentLocation = thisStructure.objectLocation;
			int objectCurrentHull = thisStructure.attributeHullCurrent;
			BOOL objectIsControlledShip = NO;
			BOOL objectIsMining = NO; // Since it is a structure
			CGPoint objectMiningLocation = CGPointZero;
			int objectCurrentCargo = 0;
			
			[thisStructureArray insertObject:[NSNumber numberWithInt:objectTypeID] atIndex:kSceneStorageIndexTypeID];
			[thisStructureArray insertObject:[NSNumber numberWithInt:objectID] atIndex:kSceneStorageIndexID];
			[thisStructureArray insertObject:objectCurrentPath atIndex:kSceneStorageIndexPath];
			[thisStructureArray insertObject:[NSNumber numberWithInt:objectAlliance] atIndex:kSceneStorageIndexAlliance];
			[thisStructureArray insertObject:[NSNumber numberWithFloat:objectRotation] atIndex:kSceneStorageIndexRotation];
			[thisStructureArray insertObject:[NSNumber numberWithBool:objectIsTraveling] atIndex:kSceneStorageIndexTraveling];
			[self insertCGPoint:objectEndLocation intoArray:thisStructureArray atIndex:kSceneStorageIndexEndLoc];
			[self insertCGPoint:objectCurrentLocation intoArray:thisStructureArray atIndex:kSceneStorageIndexCurrentLoc];
			[thisStructureArray insertObject:[NSNumber numberWithInt:objectCurrentHull] atIndex:kSceneStorageIndexHull];
			[thisStructureArray insertObject:[NSNumber numberWithBool:objectIsControlledShip] atIndex:kSceneStorageIndexControlledShip];
			[thisStructureArray insertObject:[NSNumber numberWithBool:objectIsMining] atIndex:kSceneStorageIndexMining];
			[self insertCGPoint:objectMiningLocation intoArray:thisStructureArray atIndex:kSceneStorageIndexMiningLoc];
			[thisStructureArray insertObject:[NSNumber numberWithInt:objectCurrentCargo] atIndex:kSceneStorageIndexCargo];
			if (objectID == kObjectStructureBaseStationID) {
				[finalObjectArray insertObject:thisStructureArray atIndex:0];
			} else {
				[finalObjectArray addObject:thisStructureArray];
			}
			[thisStructureArray release];
			[objectCurrentPath release];
		}
	}
	
	// Save all craft next
	for (int i = 0; i < [currentObjectArray count]; i++) {
		TouchableObject* object = [currentObjectArray objectAtIndex:i];
        if ([object destroyNow]) {
            continue;
        }
		if ([object isKindOfClass:[CraftObject class]] && ![object isKindOfClass:[SpiderDroneObject class]]) {
			// It is a craft (and not a drone!) so save it!
			NSMutableArray* thisCraftArray = [[NSMutableArray alloc] init];
			CraftObject* thisCraft = (CraftObject*)object;
			
			int objectTypeID = kObjectTypeCraft;
			int objectID = thisCraft.objectType;
			NSArray* objectCurrentPath = [[NSArray alloc] init]; // Nothing in this array for now
			int objectAlliance = thisCraft.objectAlliance;
			float objectRotation = thisCraft.objectRotation;
			BOOL objectIsTraveling = thisCraft.isTraveling;
			CGPoint objectEndLocation = thisCraft.objectLocation;
			CGPoint objectCurrentLocation = thisCraft.objectLocation;
			int objectCurrentHull = thisCraft.attributeHullCurrent;
			BOOL objectIsControlledShip = thisCraft.isBeingControlled;
			BOOL objectIsMining = NO;
			CGPoint objectMiningLocation = [thisCraft miningLocation];
			int objectCurrentCargo = [thisCraft attributePlayerCurrentCargo];
			if (thisCraft.movingAIState == kMovingAIStateMining) {
				objectIsMining = YES;
			}
            
			[thisCraftArray insertObject:[NSNumber numberWithInt:objectTypeID] atIndex:kSceneStorageIndexTypeID];
			[thisCraftArray insertObject:[NSNumber numberWithInt:objectID] atIndex:kSceneStorageIndexID];
			[thisCraftArray insertObject:objectCurrentPath atIndex:kSceneStorageIndexPath];
			[thisCraftArray insertObject:[NSNumber numberWithInt:objectAlliance] atIndex:kSceneStorageIndexAlliance];
			[thisCraftArray insertObject:[NSNumber numberWithFloat:objectRotation] atIndex:kSceneStorageIndexRotation];
			[thisCraftArray insertObject:[NSNumber numberWithBool:objectIsTraveling] atIndex:kSceneStorageIndexTraveling];
			[self insertCGPoint:objectEndLocation intoArray:thisCraftArray atIndex:kSceneStorageIndexEndLoc];
			[self insertCGPoint:objectCurrentLocation intoArray:thisCraftArray atIndex:kSceneStorageIndexCurrentLoc];
			[thisCraftArray insertObject:[NSNumber numberWithInt:objectCurrentHull] atIndex:kSceneStorageIndexHull];
			[thisCraftArray insertObject:[NSNumber numberWithBool:objectIsControlledShip] atIndex:kSceneStorageIndexControlledShip];
			[thisCraftArray insertObject:[NSNumber numberWithBool:objectIsMining] atIndex:kSceneStorageIndexMining];
			[self insertCGPoint:objectMiningLocation intoArray:thisCraftArray atIndex:kSceneStorageIndexMiningLoc];
			[thisCraftArray insertObject:[NSNumber numberWithInt:objectCurrentCargo] atIndex:kSceneStorageIndexCargo];
			[finalObjectArray addObject:thisCraftArray];
			[thisCraftArray release];
			[objectCurrentPath release];
		}
	}
	
	[plistArray insertObject:finalObjectArray atIndex:kSceneStorageGlobalObjectArray];
    [finalObjectArray release];
    NSString* fileNameAlone = [filename stringByDeletingPathExtension];
    NSString* fileNameExt = [fileNameAlone stringByAppendingString:@".plist"];
	NSString* filePath = [self documentsPathWithFilename:fileNameExt];
	if (![plistArray writeToFile:filePath atomically:YES]) {
		NSLog(@"Cannot save the current Scene!");
        [plistArray release];
        return NO;
	}
    if (currentScene.sceneType == kSceneTypeSkirmish) {
        [self addFilenameToSkirmishFileList:filename];
    }
    if (currentScene.sceneType == kSceneTypeCampaign) {
        [self addFilenameToSavedCampaignFileList:filename];
    }
    [plistArray release];
    return YES;
}

- (void)addFilenameToSkirmishFileList:(NSString*)filename {
    if ([filename caseInsensitiveCompare:kBaseCampFileName] == NSOrderedSame) { // don't worry about this for basecamp saving
        return;
    }
    NSString* filePath = [self documentsPathWithFilename:kSavedSkirmishFileName];
    NSMutableArray* plistArray = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    
    BOOL duplicate = NO;
    for (NSString* other in plistArray) {
        if ([filename caseInsensitiveCompare:other] == NSOrderedSame) {
            duplicate = YES;
        }
    }
    if (!duplicate) {
        [plistArray addObject:filename];
    } else {
        NSLog(@"Filename already exists!");
    }
    
    if (![plistArray writeToFile:filePath atomically:YES]) {
        NSLog(@"Failed to saved the scene name: %@", filename);
    }
    [plistArray release];
}

- (void)addFilenameToSavedCampaignFileList:(NSString*)filename {
    if ([filename caseInsensitiveCompare:kBaseCampFileName] == NSOrderedSame) { // don't worry about this for basecamp saving
        return;
    }
    NSString* filePath = [self documentsPathWithFilename:kSavedCampaignFileName];
    NSMutableArray* plistArray = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    
    BOOL duplicate = NO;
    for (NSString* other in plistArray) {
        if ([filename caseInsensitiveCompare:other] == NSOrderedSame) {
            duplicate = YES;
        }
    }
    if (!duplicate) {
        [plistArray addObject:filename];
    } else {
        NSLog(@"Filename already exists!");
    }
    
    if (![plistArray writeToFile:filePath atomically:YES]) {
        NSLog(@"Failed to saved the scene name: %@", filename);
    }
    [plistArray release];
}

- (void)returnToMainMenuWithSave:(BOOL)save {
    if (!isReturningToMenu) {
        isSavingFadingScene = save;
        isReturningToMenu = YES;
        isFadingSceneOut = YES;
        fadingRectAlpha = 0.0f;
    }
}

- (void)transitionToSceneWithFileName:(NSString*)fileName sceneType:(int)sceneType withIndex:(int)index isNew:(BOOL)isNewScene isLoading:(BOOL)loading {
    BroggutScene* scene = [gameScenes objectForKey:fileName];
    if (currentSceneType == kSceneTypeCampaign && isNewSceneNew) {
        [self loadCampaignLevelsForIndex:index withLoaded:isLoadingSavedScene];
        scene = [gameScenes objectForKey:fileName];
    }
    if (currentSceneType == kSceneTypeTutorial && isNewSceneNew) {
        [self loadTutorialLevelsForIndex:index];
        scene = [gameScenes objectForKey:fileName];
    }
    if (!scene || (isNewSceneNew &&
                   currentSceneType != kSceneTypeCampaign &&
                   currentSceneType != kSceneTypeTutorial)) {
        BroggutScene* newScene = [[BroggutScene alloc] initWithFileName:fileName wasLoaded:isLoadingSavedScene];
        [gameScenes setValue:newScene forKey:fileName];
        [newScene release];
        scene = newScene;
        scene.sceneType = currentSceneType;
    }
    if (scene) {
        if (transitionName) {
            [transitionName autorelease];
        }
        transitionName = [fileName copy];
        [currentScene sceneDidDisappear];
        [(OpenGLEngineAppDelegate*)[[UIApplication sharedApplication] delegate] startGLAnimation];
        self.currentScene = [gameScenes objectForKey:transitionName];
        [[ParticleSingleton sharedParticleSingleton] resetAllEmitters];
        [currentScene sceneDidAppear];
        isFadingSceneIn = YES;
        fadingRectAlpha = 1.0f;
        isAlreadyInScene = YES;
    }
}

- (void)fadeOutToSceneWithFilename:(NSString*)fileName sceneType:(int)sceneType withIndex:(int)index isNew:(BOOL)isNewScene isLoading:(BOOL)loading {
    if (transitionName) {
        [transitionName autorelease];
    }
    transitionName = [fileName copy];
    currentSceneType = sceneType;
    isNewSceneNew = isNewScene;
    isLoadingSavedScene = loading;
    currentSceneIndex = index;
    if (isAlreadyInScene) { // If already in a scene, fade that one out
        isFadingSceneOut = YES;
        fadingRectAlpha = 0.0f;
    } else {
        [self transitionToSceneWithFileName:fileName sceneType:sceneType withIndex:index isNew:isNewScene isLoading:loading];
    }
}

- (void)loadCampaignLevelsForIndex:(int)index withLoaded:(BOOL)loaded {
    switch (index) {
        case 0: {
            CampaignSceneOne* newCamp = [[CampaignSceneOne alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 1: {
            CampaignSceneTwo* newCamp = [[CampaignSceneTwo alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 2: {
            CampaignSceneThree* newCamp = [[CampaignSceneThree alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 3: {
            CampaignSceneFour* newCamp = [[CampaignSceneFour alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 4: {
            CampaignSceneFive* newCamp = [[CampaignSceneFive alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 5: {
            CampaignSceneSix* newCamp = [[CampaignSceneSix alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 6: {
            CampaignSceneSeven* newCamp = [[CampaignSceneSeven alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 7: {
            CampaignSceneEight* newCamp = [[CampaignSceneEight alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 8: {
            CampaignSceneNine* newCamp = [[CampaignSceneNine alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 9: {
            CampaignSceneTen* newCamp = [[CampaignSceneTen alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 10: {
            CampaignSceneEleven* newCamp = [[CampaignSceneEleven alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 11: {
            CampaignSceneTwelve* newCamp = [[CampaignSceneTwelve alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 12: {
            CampaignSceneThirteen* newCamp = [[CampaignSceneThirteen alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 13: {
            CampaignSceneFourteen* newCamp = [[CampaignSceneFourteen alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        case 14: {
            CampaignSceneFifteen* newCamp = [[CampaignSceneFifteen alloc] initWithLoaded:loaded];
            [gameScenes setValue:newCamp forKey:kCampaignSceneFileNames[index]];
        }
            break;
        default:
            break;
    }
    
}

- (void)loadTutorialLevelsForIndex:(int)index {
    switch (index) {
        case 0: {
            TutorialSceneOne* newTut = [[TutorialSceneOne alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 1: {
            TutorialSceneTwo* newTut = [[TutorialSceneTwo alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 2: {
            TutorialSceneThree* newTut = [[TutorialSceneThree alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 3: {
            TutorialSceneFour* newTut = [[TutorialSceneFour alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 4: {
            TutorialSceneFive* newTut = [[TutorialSceneFive alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 5: {
            TutorialSceneSix* newTut = [[TutorialSceneSix alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 6: {
            TutorialSceneSeven* newTut = [[TutorialSceneSeven alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 7: {
            TutorialSceneEight* newTut = [[TutorialSceneEight alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 8: {
            TutorialSceneNine* newTut = [[TutorialSceneNine alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 9: {
            TutorialSceneTen* newTut = [[TutorialSceneTen alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 10: {
            TutorialSceneEleven* newTut = [[TutorialSceneEleven alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 11: {
            TutorialSceneTwelve* newTut = [[TutorialSceneTwelve alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        case 12: {
            TutorialSceneThirteen* newTut = [[TutorialSceneThirteen alloc] init];
            [gameScenes setValue:newTut forKey:kTutorialSceneFileNames[index]];
        }
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Update & Render

- (void)updateCurrentSceneWithDelta:(float)aDelta {
	if (isFadingSceneIn) {
		if (fadingRectAlpha > 0.0f) {
            isFadingSceneOut = NO;
			fadingRectAlpha -= FADING_RECT_ALPHA_RATE;
		} else {
			isFadingSceneIn = NO;
			fadingRectAlpha = 0.0f;
		}
	}
	
	if (isFadingSceneOut) {
		if (fadingRectAlpha < 1.0f) {
            isFadingSceneIn = NO;
			fadingRectAlpha += FADING_RECT_ALPHA_RATE;
		} else {
            isFadingSceneOut = NO;
            isAlreadyInScene = NO;
            // Remove it from the current table of scenes
            NSString* name = [currentScene sceneFileName];
            [gameScenes removeObjectForKey:name];
            if (!isReturningToMenu) {
                [self transitionToSceneWithFileName:transitionName sceneType:currentSceneType withIndex:currentSceneIndex isNew:isNewSceneNew isLoading:isLoadingSavedScene];
            } else {
                [currentScene sceneDidDisappear];
                if (isSavingFadingScene) {
                    [(OpenGLEngineAppDelegate*)[[UIApplication sharedApplication] delegate] saveSceneAndPlayer];
                    isSavingFadingScene = NO;
                }
                [(OpenGLEngineAppDelegate*)[[UIApplication sharedApplication] delegate] stopGLAnimation];
                currentScene = nil;
            }
            isReturningToMenu = NO;
		}
	}
	[currentProfile updateProfile];
    
    if (!isShowingBroggupediaInScene || [currentScene isMultiplayerMatch])
        [currentScene updateSceneWithDelta:aDelta];
}

-(void)renderCurrentScene {
    if (!isShowingBroggupediaInScene)
        [currentScene renderScene];
    
	if (isFadingSceneIn || isFadingSceneOut) {
		enablePrimitiveDraw();
		glColor4f(0.0f, 0.0f, 0.0f, fadingRectAlpha);
		CGRect bounds = [currentScene visibleScreenBounds];
		CGRect fullRect = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
		drawFilledRect(fullRect, Vector2fZero);
		disablePrimitiveDraw();
	}
}


#pragma mark -
#pragma mark Orientation adjustment

- (CGPoint)adjustTouchOrientationForTouch:(CGPoint)aTouch inScreenBounds:(CGRect)bounds {
	
	CGPoint touchLocation = CGPointZero;
	
	if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
		touchLocation.x = kPadScreenLandscapeWidth - aTouch.y;
		touchLocation.y = kPadScreenLandscapeHeight - aTouch.x;
	} else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		touchLocation.x = aTouch.y;
		touchLocation.y = aTouch.x;
	}
	
	// Adjust for the scrolling, as this is just a location in the viewport
	touchLocation.x += bounds.origin.x;
	touchLocation.y += bounds.origin.y;
	
	return touchLocation;
}

@end

#pragma mark -
#pragma mark Private implementation

@implementation GameController (Private)

- (void)initGameController {
	
	NSLog(@"INFO - GameController: Starting game initialization.");
	
	isFadingSceneIn = NO;
	isFadingSceneOut = NO;
	fadingRectAlpha = 1.0f;
	currentScene = nil;
    isNewSceneNew = YES;
	isAlreadyInScene = NO;
    currentSceneType = kSceneTypeBaseCamp;
    currentSceneIndex = 0;
    isReturningToMenu = NO;
    isSavingFadingScene = NO;
    isShowingBroggupediaInScene = NO;
    isUpdatingCurrentScene = NO;
	
	[self loadPlayerProfile];
    [self placeInitialFilesInDocumentsFolder];
	
	interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
	
	// Load the game scenes
	gameScenes = [[NSMutableDictionary alloc] init];
	
	/*
	 [[SoundSingleton sharedSoundSingleton] loadSoundWithKey:@"testSound" soundFile:@"testsound.wav"];
	 [[SoundSingleton sharedSoundSingleton] playSoundWithKey:@"testSound"];
	 */
    
	NSLog(@"INFO - GameController: Finished game initialization.");
}

@end