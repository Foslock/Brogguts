/*
 *  Primitives.h
 *  SLQTSOR
 *
 *  Created by Mike Daley on 06/09/2009.
 *  Copyright 2009 Michael Daley. All rights reserved.
 *
 */

#import <objc/objc.h>
#import "Global.h"

static inline void enablePrimitiveDraw() {
	// Disable the color array and switch off texturing
	glDisableClientState(GL_COLOR_ARRAY);
	glDisable(GL_TEXTURE_2D);
}

static inline void disablePrimitiveDraw() {
	// Switch the color array back on and enable textures.  This is the default state
	// for our game engine
	glEnableClientState(GL_COLOR_ARRAY);
	glEnable(GL_TEXTURE_2D);
}

static inline void drawRect(CGRect aRect, Vector2f scroll) {
	
	// Setup the array used to store the vertices for our rectangle
	GLfloat* vertices = (GLfloat*)malloc( 8 * sizeof(*vertices) );
	
	// Using the CGRect that has been passed in, calculate the vertices we
	// need to render the rectangle
	vertices[0] = aRect.origin.x - scroll.x;
	vertices[1] = aRect.origin.y - scroll.y;
	vertices[2] = aRect.origin.x + aRect.size.width - scroll.x;
	vertices[3] = aRect.origin.y - scroll.y;
	vertices[4] = aRect.origin.x + aRect.size.width - scroll.x;
	vertices[5] = aRect.origin.y + aRect.size.height - scroll.y;
	vertices[6] = aRect.origin.x - scroll.x;
	vertices[7] = aRect.origin.y + aRect.size.height - scroll.y;
	
	// Set up the vertex pointer to the array of vertices we have created and
	// then use GL_LINE_LOOP to render them
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glDrawArrays(GL_LINE_LOOP, 0, 4);
	
	free(vertices);
}

static inline void drawLine(CGPoint loc1, CGPoint loc2, Vector2f scroll) {
	
	// Setup the array used to store the vertices
	GLfloat* vertices = (GLfloat*)malloc( 4 * sizeof(*vertices) );
	
	vertices[0] = loc1.x - scroll.x;
	vertices[1] = loc1.y - scroll.y;
	vertices[2] = loc2.x - scroll.x;
	vertices[3] = loc2.y - scroll.y;
	
	// Set up the vertex pointer to the array of vertices we have created and
	// then use GL_LINE_LOOP to render them
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glDrawArrays(GL_LINES, 0, 2);

	free(vertices);
}

static inline void drawLines(float* vertices, int count, Vector2f scroll) {

	glPushMatrix();
	
	// Set up the vertex pointer to the array of vertices we have created and
	// then use GL_LINE_LOOP to render them
	glTranslatef(-scroll.x, -scroll.y, 0.0f);
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glDrawArrays(GL_LINE_LOOP, 0, count);

	glPopMatrix();
}

static inline void drawDashedLine(CGPoint loc1, CGPoint loc2, int segments, Vector2f scroll) {
	float space = 0.2f;
	// Setup the array used to store the vertices
	int vertCount = (2 * segments);
	GLfloat* vertices = (GLfloat*)malloc( vertCount * 2 * sizeof(*vertices) );
	float baseX = loc1.x;
	float baseY = loc1.y;
	float xSegmentLength = (loc2.x - loc1.x) / (float)segments;
	float ySegmentLength = (loc2.y - loc1.y) / (float)segments;
	
	for (int i = 0; i < segments; i++) {
		// Put in a single segment (two points)
		int index = i * 4;
		vertices[index]   = baseX + (i * xSegmentLength) + (xSegmentLength * space) - scroll.x;
		vertices[index+1] = baseY + (i * ySegmentLength) + (ySegmentLength * space) - scroll.y;
		vertices[index+2] = baseX + ( (i+1) * xSegmentLength) - (xSegmentLength * space) - scroll.x;
		vertices[index+3] = baseY + ( (i+1) * ySegmentLength) - (ySegmentLength * space) - scroll.y;
	}
	
	vertices[0] = CLAMP(vertices[0], loc1.x - scroll.x, loc1.x - scroll.x);
	vertices[1] = CLAMP(vertices[1], loc1.y - scroll.y, loc1.y - scroll.y);
	vertices[(vertCount * 2) - 2] = CLAMP(vertices[(vertCount * 2) - 2], loc2.x - scroll.x, loc2.x - scroll.x);
	vertices[(vertCount * 2) - 1] = CLAMP(vertices[(vertCount * 2) - 1], loc2.y - scroll.y, loc2.y - scroll.y);
	
	// Set up the vertex pointer to the array of vertices we have created and
	// then use GL_LINE_LOOP to render them
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glDrawArrays(GL_LINES, 0, vertCount);
	
	free(vertices);
}

static inline void drawCircle(Circle aCircle, uint aSegments, Vector2f scroll) {
	
	// Set up the array that will store our vertices.  Each segment will need
	// two vertices {x, y} so we multiply the segments passedin by 2
	GLfloat* vertices = (GLfloat*)malloc( (aSegments*2) * sizeof(*vertices) );
	
	// Set up the counter that will track the number of vertices we will have
	int vertexCount = 0;
	
	// Loop through each segment creating the vertices for that segment and add
	// the vertices to the vertices array
	for(int segment = 0; segment < aSegments; segment++) 
	{ 
		// Calculate the angle based on the number of segments
		float theta = 2.0f * M_PI * (float)segment / (float)aSegments;
		
		// Calculate the x and y position of the current segment
		float x = aCircle.radius * cosf(theta) - scroll.x;
		float y = aCircle.radius * sinf(theta) - scroll.y;
		
		// Add the new vertices to the vertices array taking into account the circles
		// current x and y position
		vertices[vertexCount++] = x + aCircle.x;
		vertices[vertexCount++] = y + aCircle.y;
	}
	
	// Set up the vertex pointer to the array of vertices we have created and
	// then use GL_LINE_LOOP to render them
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glDrawArrays(GL_LINE_LOOP, 0, aSegments);
	
	free(vertices);
}