/*
 
 File: UIElementUtilities.h
 
 Abstract: Utility methods - Header file.
 
 Version: 1.0
 
 Last updated: 10 October 2011
 Author: Peter Burkimsher
 peterburk@gmail.com
 
 Copyright © 2011 YGuoren
 
 */

// Import general libraries
#import <Cocoa/Cocoa.h>

// Global variable for text to be returned if there is no description
extern NSString *const UIElementUtilitiesNoDescription;

// Inspector window - Class
@class InspectorWindowController;

// UI element interface
@interface UIElementUtilities : NSObject 
{
    InspectorWindowController		    *_inspectorWindowController;
}

#pragma mark -
#pragma mark AXUIElementRef cover methods
/* These methods cover the bulk of the AXUIElementRef API found in <HIServices/AXUIElement.h> */

// Read attribute names from a UI element
+ (NSArray *)attributeNamesOfUIElement:(AXUIElementRef)element;

// Read the value of a particular attribute from a UI element
+ (id)valueOfAttribute:(NSString *)attribute ofUIElement:(AXUIElementRef)element;

// Read whether the value of a particular attribute of a UI element can be set
+ (BOOL)canSetAttribute:(NSString *)attributeName ofUIElement:(AXUIElementRef)element;

// Takes a string value, converts the string to numbers, ranges, points, sizes, rects, if required
+ (void)setStringValue:(NSString *)stringValue forAttribute:(NSString *)attribute ofUIElement:(AXUIElementRef)element;

// Read actions to be performed on a UI element
+ (NSArray *)actionNamesOfUIElement:(AXUIElementRef)element;

// Read descriptions of actions to be performed on a UI element
+ (NSString *)descriptionOfAction:(NSString *)actionName ofUIElement:(AXUIElementRef)element;

// Perform an action on a UI element
+ (void)performAction:(NSString *)actionName ofUIElement:(AXUIElementRef)element;

// Get the current application. Returns 0 if process ID could not be found. (Process 0 is command-line only).
+ (pid_t)processIdentifierOfUIElement:(AXUIElementRef)element;


#pragma mark -
#pragma mark Convenience Methods
/* Convenience methods to return commonly requested attributes of a UI element */

// Return the frame of the UI element in Cocoa screen coordinates
+ (NSRect)frameOfUIElement:(AXUIElementRef)element;

// Get the parent of a particular UI element
+ (AXUIElementRef)parentOfUIElement:(AXUIElementRef)element;

// Get the role of a particular UI element
+ (NSString *)roleOfUIElement:(AXUIElementRef)element;

// Get the title of a particular UI element
+ (NSString *)titleOfUIElement:(AXUIElementRef)element;

// Is the UI element part of an application?
+ (BOOL)isApplicationUIElement:(AXUIElementRef)element;

#pragma mark -
// Convert from NSPoint to CGPoint screen geometry
+ (CGPoint)carbonScreenPointFromCocoaScreenPoint:(NSPoint)cocoaPoint;

#pragma mark -
#pragma mark String Descriptions
/* Methods to return the various strings displayed in the interface */

// Get the string value of the UI element (not just the AXDescription). 
+ (NSString *)stringDescriptionOfUIElement:(AXUIElementRef)inElement;

// Get the full description of the UI element
+ (NSString *)descriptionForUIElement:(AXUIElementRef)uiElement attribute:(NSString *)name beingVerbose:(BOOL)beVerbose;

// Get the description of the AXDescription of the UI element
+ (NSString *)descriptionOfAXDescriptionOfUIElement:(AXUIElementRef)element;

@end
// end UI element interface