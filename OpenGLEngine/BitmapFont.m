//
//  BitMapFont.m
//  SLQTSOR
//
//  Created by Michael Daley on 08/03/2009.
//  Copyright 2009 Michael Daley. All rights reserved.
//

#import "BitmapFont.h"
#import "GameController.h"
#import "BroggutScene.h"
#import "Image.h"
#import "TextObject.h"

#pragma mark -
#pragma mark Private interface

@interface BitmapFont (Private)
// Takes the control file and parses the information within it
- (void)parseFont:(NSString*)controlFile;

// Parses the common configuration line within the control file.  This contains information for
// the common height of the font which is used when calculating the position of the font characters
// on the screen.
- (void)parseCommon:(NSString*)line;

// Parses the individual character definitions which are identified by the parseFont method.
// This method also assiciates an image with each character
- (void)parseCharacterDefinition:(NSString*)line;

@end

#pragma mark -
#pragma mark Public implementation

@implementation BitmapFont

@synthesize fontImage;
@synthesize fontColor;

- (void)dealloc {
	// Free the objects which are being held within the charsArray
	if (charsArray) {
		for(int i=0; i < kMaxCharsInFont; i++) {
			if (charsArray[i].image)
				[charsArray[i].image release];
		}
		free(charsArray);
	}
	if (fontImage)
		[fontImage release];
	[super dealloc];
}

- (id)initWithFontImageNamed:(NSString*)aFileName controlFile:(NSString*)aControlFile scale:(Scale2f)aScale filter:(GLenum)aFilter {
	self = [self init];
	if (self != nil) {
        
		sharedGameController = [GameController sharedGameController];
		
		// Reference the font image which has been supplied and which contains the character bitmaps
		fontImage = [[Image alloc] initWithImageNamed:aFileName filter:aFilter];
        originalScale = aScale;
        fontImage.scale = aScale;
        
		// Set up the initial color
		fontColor = Color4fMake(1.0f, 1.0f, 1.0f, 1.0f);
        
        // Initialize the array which is going to hold the bitmapfontchar structures
		charsArray = calloc(kMaxCharsInFont, sizeof(BitmapFontChar));
        
        // Parse the control file and populate charsArray which the character definitions
		[self parseFont:aControlFile];
	}
	return self;
}

- (id)initWithImage:(Image*)aImage controlFile:(NSString*)aControlFile scale:(Scale2f)aScale filter:(GLenum)aFilter {
	self = [self init];
	if (self != nil) {
		
		sharedGameController = [GameController sharedGameController];
		
		// Reference the font image which has been supplied and which contains the character bitmaps
		self.fontImage = aImage;
        originalScale = aScale;
        self.fontImage.scale = aScale;
        
		// Set up the initial color
		fontColor = Color4fMake(1.0f, 1.0f, 1.0f, 1.0f);
		
        // Initialize the array which is going to hold the bitmapfontchar structures
		charsArray = calloc(kMaxCharsInFont, sizeof(BitmapFontChar));
		
        // Parse the control file and populate charsArray which the character definitions
		[self parseFont:aControlFile];
	}
	return self;
}

- (void)renderTextObject:(TextObject*)obj{
	[self renderStringAt:obj.objectLocation text:obj.objectText onLayer:obj.renderLayer];
}

- (void)setFontScale:(Scale2f)scale {
    [fontImage setScale:scale];
}

- (void)resetFontScale {
    [fontImage setScale:originalScale];
}

- (void)renderStringAt:(CGPoint)aPoint text:(NSString*)aText onLayer:(GLuint)layer {
    
	// Grab the scale that we will be using
	float xScale = fontImage.scale.x;
	float yScale = fontImage.scale.y;
    CGPoint originalPoint = aPoint;
	
	// Loop through all the characters in the text to be rendered
	for(int i = 0; i < [aText length]; i++) {
		
		// Grab the character value of the current character.  We take off 32 as the first
		// 32 characters of the fonts are not used
		unichar charID = [aText characterAtIndex:i] - 32;
        charsArray[charID].image.scale = fontImage.scale;
        Image* charImage = charsArray[charID].image;
        
        if ([aText characterAtIndex:i] == '\n') {
            aPoint.x = originalPoint.x;
            aPoint.y -= (lineHeight * yScale);
            continue;
        }
		
		// Using the current x and y, calculate the correct position of the character using the x and y offsets for each character.
		// This will cause the characters to all sit on the line correctly with tails below the line.  The commonHeight which has
		// been taken from the fonts control file is used within the calculation.
		int y = aPoint.y + (lineHeight * yScale) - (charsArray[charID].height + charsArray[charID].yOffset) * yScale;
		int x = aPoint.x + charsArray[charID].xOffset;
		CGPoint renderPoint = CGPointMake(x, y);
		
		// Set the color of this character based on the fontColor
		charImage.color = fontColor;
        charImage.renderLayer = layer;
		
		// Render the current character at the renderPoint
		[charImage renderAtPoint:renderPoint];
        
		// Move x based on the amount to advance for the current char
		aPoint.x += charsArray[charID].xAdvance * xScale;
	}
}

- (void)renderStringAt:(CGPoint)aPoint text:(NSString*)aText onLayer:(GLuint)layer withWidthLimit:(float)widthLimit {
    
    // Grab the scale that we will be using
    CGPoint oldPoint = aPoint;
	float xScale = fontImage.scale.x;
	float yScale = fontImage.scale.y;
    int currentLine = 0;
    int textLength = [aText length];
	
	// Loop through all the characters in the text to be rendered
	for(int i = 0; i < textLength; i++) {
		
		// Grab the character value of the current character.  We take off 32 as the first
		// 32 characters of the fonts are not used
		unichar charID = [aText characterAtIndex:i] - 32;
        charsArray[charID].image.scale = fontImage.scale;
        Image* charImage = charsArray[charID].image;
        
        // If it is a new line, just skip down to next line
        if ([aText characterAtIndex:i] == '\n') {
            aPoint.x = oldPoint.x;
            currentLine++;
            continue;
        }
		
		// Using the current x and y, calculate the correct position of the character using the x and y offsets for each character.
		// This will cause the characters to all sit on the line correctly with tails below the line.  The commonHeight which has
		// been taken from the fonts control file is used within the calculation.
        float totalWordLength = 0.0f;
        for (int j = i; j < textLength; j++) {
            char thisChar = [aText characterAtIndex:j];
            unichar charID = thisChar - 32;
            if ( thisChar == ' ' || thisChar == '\n') {
                break;
            }
            totalWordLength += charsArray[charID].xAdvance * xScale;
        }
        
        if ( (aPoint.x + totalWordLength) >= (oldPoint.x + widthLimit) ) {
            aPoint.x = oldPoint.x;
            currentLine++;
        }
        
		int y = aPoint.y - (currentLine * ((lineHeight * yScale) + 2.0f)) + (lineHeight * yScale) - (charsArray[charID].height + charsArray[charID].yOffset) * yScale;
		int x = aPoint.x + charsArray[charID].xOffset;
		CGPoint renderPoint = CGPointMake(x, y);
		
		// Set the color of this character based on the fontColor
		charImage.color = fontColor;
        charImage.renderLayer = layer;
		
		// Render the current character at the renderPoint
		[charImage renderAtPoint:renderPoint];
        
		// Move x based on the amount to advance for the current char
		aPoint.x += charsArray[charID].xAdvance * xScale;
	}
}

- (void)renderStringJustifiedInFrame:(CGRect)aRect justification:(int)aJustification text:(NSString*)aText onLayer:(GLuint)layer {
	CGPoint point = CGPointZero;
    
    int charCount = [aText length];
    float totalLineCount = 0.0f;
    for (int i = 0; i < charCount; i++) {
        char thisChar = [aText characterAtIndex:i];
        if (thisChar == '\n') {
            totalLineCount++;
        }
    }
    NSString* currentText = @"";
    float lineCount = 1.0f;
    for (int i = 0; i < charCount; i++) {
        char thisChar = [aText characterAtIndex:i];
        if (thisChar == '\n' || i == charCount - 1) {
            // write out current string
            if (thisChar != '\n') {
                currentText = [currentText stringByAppendingFormat:@"%c", thisChar];
            }
            // Calculate the width and height in pixels of the text
            float textWidth = [self getWidthForString:currentText];
            float textHeight = [self getHeightForString:currentText];
            float scaledLineHeight = (lineHeight * fontImage.scale.y) * (lineCount - (totalLineCount / 2));
            
            // Based on the justification enum calculate the position of the text
            switch (aJustification) {
                case BitmapFontJustification_TopLeft:
                    point.x = aRect.origin.x;
                    point.y = aRect.origin.y + (aRect.size.height - textHeight) - (scaledLineHeight - textHeight);
                    break;
                case BitmapFontJustification_MiddleLeft:
                    point.x = aRect.origin.x;
                    point.y = aRect.origin.y + ((aRect.size.height - textHeight) / 2) - (scaledLineHeight - textHeight);		
                    break;
                case BitmapFontJustification_BottomLeft:
                    point.x = aRect.origin.x;
                    point.y = aRect.origin.y - (scaledLineHeight - textHeight);
                    break;
                case BitmapFontJustification_TopCentered:
                    point.x = aRect.origin.x + ((aRect.size.width - textWidth) / 2);
                    point.y = aRect.origin.y + (aRect.size.height - textHeight) - (scaledLineHeight - textHeight);
                    break;
                case BitmapFontJustification_MiddleCentered:
                    point.x = aRect.origin.x + ((aRect.size.width - textWidth) / 2);
                    point.y = aRect.origin.y + ((aRect.size.height - textHeight) / 2) - (scaledLineHeight - textHeight);
                    break;
                case BitmapFontJustification_BottomCentered:
                    point.x = aRect.origin.x + ((aRect.size.width - textWidth) / 2);
                    point.y = aRect.origin.y - (scaledLineHeight - textHeight);
                    break;
                case BitmapFontJustification_TopRight:
                    point.x = aRect.origin.x + (aRect.size.width - textWidth);
                    point.y = aRect.origin.y + (aRect.size.height - textHeight) - (scaledLineHeight - textHeight);
                    break;
                case BitmapFontJustification_MiddleRight:
                    point.x = aRect.origin.x + (aRect.size.width - textWidth);
                    point.y = aRect.origin.y + ((aRect.size.height - textHeight) / 2) - (scaledLineHeight - textHeight);
                    break;
                case BitmapFontJustification_BottomRight:
                    point.x = aRect.origin.x + (aRect.size.width - textWidth);
                    point.y = aRect.origin.y - (scaledLineHeight - textHeight);
                    break;
                default:
                    break;
            }
            
            // Now we have calcualted the point to render the text, use the standard render method to actually render the text
            // at the point calculated
            [self renderStringAt:point text:currentText onLayer:layer];
            currentText = @"";
            if (thisChar == '\n') {
                lineCount += 1.0f;
            }
        } else {
            currentText = [currentText stringByAppendingFormat:@"%c", thisChar];
        }
    }
}

- (int)getWidthForString:(NSString*)string {
	// Set up stringWidth
	int stringWidth = 0;
	int maxWidth = 0;
	// Loop through the characters in the text and sum the xAdvance for each one
	// xAdvance holds how far x should be advanced for each character so that the correct
	// space is left after each character.
	for(int index=0; index<[string length]; index++) {
		unichar charID = [string characterAtIndex:index] - 32;
        if ([string characterAtIndex:index] == '\n') {
            if (stringWidth > maxWidth) {
                maxWidth = stringWidth;
                stringWidth = 0;
            }
        }
        
		// Add the xAdvance value of the current character to stringWidth scaling as necessary
		stringWidth += charsArray[charID].xAdvance * fontImage.scale.x;
	}	
    
	// Return the total width calculated
	return stringWidth;
}


- (int)getHeightForString:(NSString*)string {
	// Set up stringHeight	
	int stringHeight = 0;
    
	// Loop through the characters in the text and sum the height.  The sum will take into
	// account the offset of the character as some characters sit below the line etc
	for(int i=0; i<[string length]; i++) {
		unichar charID = [string characterAtIndex:i] - 32;
		
		// Don't bother checking if the character is a space as they have no height
		if(charID == ' ')
			continue;
        
        if ([string characterAtIndex:i] == '\n') {
            stringHeight += lineHeight;
            continue;
        }
		
		// Check to see if the height of the current character is greater than the current max height
		// If so then replace the current stringHeight with the height of the current character
		stringHeight = MAX((charsArray[charID].height * fontImage.scale.y) + (charsArray[charID].yOffset * fontImage.scale.y), stringHeight);
	}	
	// Return the total height calculated
	return stringHeight;	
}

@end

#pragma mark -
#pragma mark Private implementation

@implementation BitmapFont (Private)

- (void)parseFont:(NSString*)controlFile {
    
	// Read the contents of the file into a string
	NSString *contents = [NSString stringWithContentsOfFile:
						  [[NSBundle mainBundle] pathForResource:controlFile ofType:@"fnt"] encoding:NSASCIIStringEncoding error:nil];
    
	// Move all lines in the string, which are denoted by \n, into an array
	NSArray *lines = [[NSArray alloc] initWithArray:[contents componentsSeparatedByString:@"\n"]];
    
	// Create an enumerator which we can use to move through the lines read from the control file
	NSEnumerator *nse = [lines objectEnumerator];
    
	// Create a holder for each line we are going to work with
	NSString *line;
    
	// Loop through all the lines in the lines array processing each one
	while((line = [nse nextObject])) {
		// Check to see if the start of the line is something we are interested in
        if([line hasPrefix:@"common"]) {
            [self parseCommon:line];
        } else if([line hasPrefix:@"char id"]) {
			// Parse the current line and create a new CharDef
			[self parseCharacterDefinition:line];
		}
	}
	// Finished with lines so release it
	[lines release];
}

- (void)parseCommon:(NSString*)line {
    
	// Set up the variables that are going to hold the information for the common line
	int scaleW;
	int scaleH;
	int pages;
    
	// Grab information from the common line
	sscanf([line UTF8String], "common lineHeight=%i base=%*i scaleW=%i scaleH=%i pages=%i", &lineHeight, &scaleW, &scaleH, &pages);
	
    // scaleW is the width of the texture atlas for this font.
    NSAssert(scaleW <= 1024, @"ERROR - BitmapFont: Texture atlas cannot be larger than 1024x1024");
    // scaleH is the height of the texture atlas for this font.
    NSAssert(scaleH <= 1024, @"ERROR - BitmapFont: Texture atlas cannot be larger than 1024x1024");
    // pages are the number of different texture atlas files being used for this font
    NSAssert(pages == 1, @"ERROR - BitmapFont: Only supports fonts with a single texture atlas.");
}

- (void)parseCharacterDefinition:(NSString*)line {
    
	// Set up the variable to store the character ID for the character being processed
	int charID;
	
	// Grab the character ID from line
	sscanf([line UTF8String], "char id=%i", &charID);
    
	// Take 32 from the charID as we are not using the first 32 characters of the font
	charID -= 32;
	
	// Grab the remaining data from line that defines the character information
	sscanf([line UTF8String], "char id=%*i x=%i y=%i width=%i height=%i xoffset=%i yoffset=%i xadvance=%i",
		   &charsArray[charID].x, &charsArray[charID].y, &charsArray[charID].width,
		   &charsArray[charID].height, &charsArray[charID].xOffset, &charsArray[charID].yOffset, &charsArray[charID].xAdvance);
    
    // Populate image with a new image instance defined as the sub image region for this
    // character.
    charsArray[charID].image = [[fontImage subImageInRect:CGRectMake(charsArray[charID].x, 
                                                                     charsArray[charID].y, 
                                                                     charsArray[charID].width, 
                                                                     charsArray[charID].height)] retain];
    
    // Set the scale of this characters image to match the scale of the texture atlas for this font
    charsArray[charID].image.scale = fontImage.scale;
}

@end

