//
//  CollisionManager.h
//  OpenGLEngine
//
//  Created by James F Lockwood on 2/9/11.
//  Copyright 2011 Games in Dorms. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BroggutObject;
@class BroggutGenerator;

typedef struct Object_ID_Array {
	int* objectIDArray; // Array of objects in that cell
	int arrayCount;		// Number of objects in the array
	int arrayCapacity;	// The Capacity of the array
} ObjectIDArray;

typedef struct Medium_Broggut {
	int broggutID;		// This is the unique broggut ID, empty or not, all spots have this
	int broggutValue;	// This is the number of brogguts in this broggut cell, if -1, then spot is empty
	int broggutAge;		// The rarity of the broggut (0 - young, 1 - old, 2 - ancient)
	int broggutEdge;	// If the broggut is on the edge of a large broggut
} MediumBroggut;

typedef struct Broggut_Array {
	MediumBroggut* array;	// This is the 1D->2D mapped array of medium brogguts
	int bWidth;				// This is the number of cells wide the array is
	int bHeight;			// This is the number of cells high the array is
	int broggutCount;		// The number of medium brogguts in the array (values != -1)
} BroggutArray;

@class CollidableObject;

#define INITIAL_HASH_CAPACITY 20 // Initial capacity of each cell for UIDs
#define INITIAL_TABLE_CAPACITY 100 // Initial capacity of the table holding all CollidableObjects
#define COLLISION_DETECTION_FREQ 2 // How many frames to wait to check collisions (0 - every frame, 1 - every other, 2 every second, etc.)
#define CHECK_ONLY_OBJECTS_ONSCREEN YES // Only perform collision detection for objects on screen

@interface CollisionManager : NSObject {
	NSMutableDictionary* objectTable;	// This keeps tracks of all objects that have been added, indexed by their UID
	ObjectIDArray* cellHashTable;		// Table that contains an array for each cell on the screen, index is the location "hashed"
										// and the contents is an array of UIDs for each object in that cell
	NSMutableArray* bufferNearbyObjects;// Buffer that will be used during loops to store nearby objects
	CGRect fullMapBounds;				// The entire map rectangle
	float* gridVertexArray;				// Vertexes of the grid if we want to draw it
	Scale2f currentGridScale;				// The scale of the grid
	float cellWidth;					// The width of a cell dividing the rect
	float cellHeight;					// The height " "
	int numberOfColumns;				// Number of cell columns
	int numberOfRows;					// Number of cell rows
	
	BroggutArray* broggutArray;			// A 2D array of brogguts
	BroggutGenerator* generator;		// The generator the makes the medium brogguts
}

- (id)initWithContainingRect:(CGRect)bounds WithCellWidth:(float)width withHeight:(float)height;

- (void)remakeGenerator;

- (MediumBroggut*)broggutCellForLocation:(CGPoint)location;
- (int)getBroggutIDatLocation:(CGPoint)location;
- (CGPoint)getBroggutLocationForID:(int)brogid;
- (BOOL)isLocationOccupiedByBroggut:(CGPoint)location;
- (CGPoint)getLocationOfClosestMediumBroggutToPoint:(CGPoint)location;
- (int)getBroggutValueAtLocation:(CGPoint)location;
- (int)getBroggutValueWithID:(int)brogID;
- (void)setBroggutValue:(int)newValue withID:(int)brogID;

- (void)updateMediumBroggutEdgeAtLocation:(CGPoint)location;
- (void)updateAllMediumBroggutsEdges;
- (void)addMediumBroggut;
- (void)renderMediumBroggutsInScreenBounds:(CGRect)bounds withScrollVector:(Vector2f)scroll;

- (void)remakeGridVertexArrayWithScale:(Scale2f)scale;

- (void)addCollidableObject:(CollidableObject*)object;
- (void)removeCollidableObject:(CollidableObject*)object;

- (void)putNearbyObjectsToID:(int)objectID intoArray:(NSMutableArray*)array;
- (void)putNearbyObjectsToLocation:(CGPoint)location intoArray:(NSMutableArray*)array;
- (BroggutObject*)closestSmallBroggutToLocation:(CGPoint)location;

- (void)updateAllObjectsInTableInScreenBounds:(CGRect)bounds;
- (void)processAllCollisionsWithScreenBounds:(CGRect)bounds;

- (int)getIndexForLocation:(CGPoint)location;

- (void)drawCellGridAtPoint:(CGPoint)center withScale:(Scale2f)scale withScroll:(Vector2f)scroll withAlpha:(float)alpha;

@end
