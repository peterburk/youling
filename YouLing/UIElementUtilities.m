/*
 
 File: UIElementUtilities.m
 
 Abstract: Utility methods - Main file.
 
 Version: 1.0
 
 Last updated: 10 October 2011
 Author: Peter Burkimsher
 peterburk@gmail.com
 
 Copyright © 2011 YGuoren
 
 */

// Import application-specific headers
#import "UIElementUtilities.h"
#import "AppDelegate.h"

// Global variable, string to be returned if there is no description
NSString *const UIElementUtilitiesNoDescription = @"No Description";

// UI element - Implementation
@implementation UIElementUtilities


#pragma mark -

/*
 * processIdentifierOfUIElement: Get the process ID of the application owning a particular UI element
 * @param AXUIElementRef element: The UI element to trace the parent application for
 * @return pid_t: The process ID of the parent application
 */
+ (pid_t)processIdentifierOfUIElement:(AXUIElementRef)element 
{
    // Initialise the process ID to 0
    pid_t pid = 0;
    
    // Try to get the process ID
    if (AXUIElementGetPid (element, &pid) == kAXErrorSuccess) 
    {
        // On success, return the process ID
        return pid;
    } else {
        // If not, return failure
        return 0;
    }
}

/*
 * attributeNamesOfUIElement: Find the attributes of a particular UI element
 * @param AXUIElementRef element: The UI element to find attributes for
 * @return NSArray*: The attributes of the UI element
 */
+ (NSArray *)attributeNamesOfUIElement:(AXUIElementRef)element 
{
    // Initialise the array of attribute names
    NSArray* attrNames = nil;
    
    // Read the attribute names from the UI element
    AXUIElementCopyAttributeNames(element, (CFArrayRef *)&attrNames);
    
    // Return the attribute names, and release when ready
    return [attrNames autorelease];
}

/*
 * actionNamesOfUIElement: Find the actions to be performed on a particular UI element
 * @param AXUIElementRef element: The UI element to find actions for
 * @return NSArray*: The actions for the UI element
 */
+ (NSArray *)actionNamesOfUIElement:(AXUIElementRef)element 
{
    // Initialise the array of action names
    NSArray *actionNames = nil;
    
    // Read the action names from the UI element
    AXUIElementCopyActionNames(element, (CFArrayRef *)&actionNames);
    
    // Return the action names, and release when ready
    return [actionNames autorelease];
}

/*
 * descriptionOfAction: Get the description of an action to be performed on a particular UI element
 * @param NSString* actionName: The name of the action
 *        AXUIElementRef element: The UI element
 * @return NSString*: The description of the action for that UI element
 */
+ (NSString *)descriptionOfAction:(NSString *)actionName ofUIElement:(AXUIElementRef)element 
{
    // Initialise an action description string
    NSString *actionDescription = nil;
    
    // Read the action description from the UI element
    AXUIElementCopyActionDescription(element, (CFStringRef)actionName, (CFStringRef *)&actionDescription);
    
    // Return the action description, and release when ready
    return [actionDescription autorelease];
}

/*
 * performAction: Perform an action on a particular UI element
 * @param NSString* actionName: The name of the action
 *        AXUIElementRef element: The UI element
 */
+ (void)performAction:(NSString *)actionName ofUIElement:(AXUIElementRef)element 
{
    // Perform the action
    AXUIElementPerformAction( element, (CFStringRef)actionName);
}


/*
 * valueOfAttribute: Get the value of an attribute of a particular UI element
 * @param NSString* attribute: The name of the attribute
 *        AXUIElementRef element: The UI element
 * @return id: The value of the attribute of that UI element
 */
+ (id)valueOfAttribute:(NSString *)attribute ofUIElement:(AXUIElementRef)element
{
    // Initialise the return variable
    id result = nil;
    
    // Read all the attribute names
    NSArray *attributeNames = [UIElementUtilities attributeNamesOfUIElement:element];
    
    // If there are attribute names
    if (attributeNames)
    {
        // If the attribute names contain the attribute, read the value
        if ( [attributeNames indexOfObject:(NSString *)attribute] != NSNotFound
            &&
        	AXUIElementCopyAttributeValue(element, (CFStringRef)attribute, (CFTypeRef *)&result) == kAXErrorSuccess
            ) {
            // Set the result variable to the value
            [result autorelease];
        }
    }
    
    // Return the value of the attribute
    return result;
}

/*
 * canSetAttribute: Find whether the value of an attribute of a particular UI element can be set
 * @param NSString* attributeName: The name of the attribute
 *        AXUIElementRef element: The UI element
 * @return BOOL: The value of the attribute of that UI element can be set
 */
+ (BOOL)canSetAttribute:(NSString *)attributeName ofUIElement:(AXUIElementRef)element
{
    // Initialise the return variable
    Boolean isSettable = false;
    
    // Read whether the attribute can be set
    AXUIElementIsAttributeSettable(element, (CFStringRef)attributeName, &isSettable);
    
    // Return whether the attribtue can be set
    return (BOOL)isSettable;
}

/*
 * setStringValue: Set the value of an attribute of a particular UI element
 * @param NSString* stringValue: The value to set the attribute to
 *        NSString* attributeName: The name of the attribute
 *        AXUIElementRef element: The UI element
 * @return BOOL: The value of the attribute of that UI element can be set
 */
+ (void)setStringValue:(NSString *)stringValue forAttribute:(NSString *)attributeName ofUIElement:(AXUIElementRef)element;
{
    // Read the current value of the attribute
    CFTypeRef theCurrentValue = NULL;
    
    // Find out what type of value it is.
    if ( attributeName
        && AXUIElementCopyAttributeValue( element, (CFStringRef)attributeName, &theCurrentValue ) == kAXErrorSuccess
        && theCurrentValue) 
    {
        // Get a reference to the value
        CFTypeRef	valueRef = NULL;
        
        // If the value is a CGPoint. Todo: Remove surplus code. 
        if (AXValueGetType(theCurrentValue) == kAXValueCGPointType) 
        {
            float x, y;
            sscanf( [stringValue UTF8String], "x=%g y=%g", &x, &y );
            CGPoint point = CGPointMake(x, y);
            valueRef = AXValueCreate( kAXValueCGPointType, (const void *)&point );
            if (valueRef) 
            {
                AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, valueRef );
                CFRelease( valueRef );
            }
        }
     	// If the value is a CGSize. Todo: Remove surplus code. 
        else if (AXValueGetType(theCurrentValue) == kAXValueCGSizeType) 
        {
            float w, h;
            sscanf( [stringValue UTF8String], "w=%g h=%g", &w, &h );
            CGSize size = CGSizeMake(w, h);
            valueRef = AXValueCreate( kAXValueCGSizeType, (const void *)&size );
            if (valueRef) {
                AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, valueRef );
                CFRelease( valueRef );
            }
        }
        // If the value is a CGRect. Todo: Remove surplus code. 
     	else if (AXValueGetType(theCurrentValue) == kAXValueCGRectType)
        {
            float x, y, w, h;
            sscanf( [stringValue UTF8String], "x=%g y=%g w=%g h=%g", &x, &y, &w, &h );
            CGRect rect = CGRectMake(x, y, w, h);
            valueRef = AXValueCreate( kAXValueCGRectType, (const void *)&rect );
            if (valueRef) {
                AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, valueRef );
                CFRelease( valueRef );
            }
        }
        // If the value is a CFRange. Todo: Remove surplus code. 
     	else if (AXValueGetType(theCurrentValue) == kAXValueCFRangeType)
        {
            CFRange range;
            sscanf( [stringValue UTF8String], "pos=%ld len=%ld", &(range.location), &(range.length) );
            valueRef = AXValueCreate( kAXValueCFRangeType, (const void *)&range );
            if (valueRef) {
                AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, valueRef );
                CFRelease( valueRef );
            }
        }
        // If the value is an NSString
        else if ([(id)theCurrentValue isKindOfClass:[NSString class]])
        {
            // Set the value of the NSString
            AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, stringValue );
        }
        // If the value is an NSValue
        else if ([(id)theCurrentValue isKindOfClass:[NSValue class]])
        {
            // Set the value of the NSValue
            AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, [NSNumber numberWithFloat:[stringValue floatValue]] );
        }
    }
}


/*
 * parentOfUIElement: Get the parent of a particular UI element
 * @param AXUIElementRef element: The UI element
 * @return AXUIElementRef: The parent of that UI element
 */
+ (AXUIElementRef)parentOfUIElement:(AXUIElementRef)element 
{
    // Read the parent attribute
    return (AXUIElementRef)[UIElementUtilities valueOfAttribute:NSAccessibilityParentAttribute ofUIElement:element];
}

/*
 * roleOfUIElement: Get the role of a particular UI element
 * @param AXUIElementRef element: The UI element
 * @return NSString*: The role of that UI element
 */
+ (NSString *)roleOfUIElement:(AXUIElementRef)element 
{
    // Read the role attribute
    return (NSString *)[UIElementUtilities valueOfAttribute:NSAccessibilityRoleAttribute ofUIElement:element];
}

/*
 * titleOfUIElement: Get the title of a particular UI element
 * @param AXUIElementRef element: The UI element
 * @return NSString*: The role of that UI element
 */
+ (NSString *)titleOfUIElement:(AXUIElementRef)element 
{
    // Read the title attribute
    return (NSString *)[UIElementUtilities valueOfAttribute:NSAccessibilityTitleAttribute ofUIElement:element];
}

/*
 * isApplicationUIElement: Get whether the role of a particular UI element is an application role
 * @param AXUIElementRef element: The UI element
 * @return BOOL: The role of that UI element
 */
+ (BOOL)isApplicationUIElement:(AXUIElementRef)element
{
    // Read the application role attribute
    return [[UIElementUtilities roleOfUIElement:element] isEqualToString:NSAccessibilityApplicationRole];
}



#pragma mark -

/*
 * carbonScreenPointFromCocoaScreenPoint: Convert NSPoint to CGPoint. 
 * @param NSPoint cocoaPoint: A location of the cursor on the screen
 * @return CGPoint: The location as a CoreGraphics type
 */
+ (CGPoint)carbonScreenPointFromCocoaScreenPoint:(NSPoint)cocoaPoint 
{
    // Support multiple screens by finding the relevant screen for the point
    NSScreen *foundScreen = nil;
    
    // Declare the return variable
    CGPoint thePoint;
    
    // Search all screens
    for (NSScreen *screen in [NSScreen screens]) 
    {
        // If the NSPoint is on the screen
        if (NSPointInRect(cocoaPoint, [screen frame])) 
        {
            // Set the foundScreen variable
            foundScreen = screen;
        }
    }
    
    // If the point is found to be on-screen somewhere
    if (foundScreen) 
    {
        // Find the height of the screen
        CGFloat screenHeight = [foundScreen frame].size.height;
        
        // Flip the height coordinate (from bottom, rather than top)
        thePoint = CGPointMake(cocoaPoint.x, screenHeight - cocoaPoint.y - 1);
    } else {
        // If the point is not on-screen, initialise it to zero
        thePoint = CGPointMake(0.0, 0.0);
    }
    
    // Return the point. It's more than just a great church: http://pointchurch.ca/ . 
    return thePoint;
}


/*
 * flippedScreenBounds: Find the bounds of the screen's current frame, even when flipped. 
 * @param NSRect bounds: The apparent bounds of the screen
 * @return NSRect: The actual bounds of the screen
 */
+ (NSRect) flippedScreenBounds:(NSRect) bounds
{
    // Find the height of the first screen's frame
    float screenHeight = NSMaxY([[[NSScreen screens] objectAtIndex:0] frame]);
    
    // Subtract the bounds of the input frame
    bounds.origin.y = screenHeight - NSMaxY(bounds);
    
    // Return the resulting bounds
    return bounds;
}

/*
 * frameOfUIElement: Find the frame of the current UI element. 
 * @param AXUIElementRef element: The UI element
 * @return NSRect: The frame of the current UI element
 */
+ (NSRect)frameOfUIElement:(AXUIElementRef)element 
{
    // Initialise the return variable
    NSRect bounds = NSZeroRect;
    
    // Find the position of the UI element
    id elementPosition = [UIElementUtilities valueOfAttribute:NSAccessibilityPositionAttribute ofUIElement:element];
    
    // Find the size of the UI element
    id elementSize = [UIElementUtilities valueOfAttribute:NSAccessibilitySizeAttribute ofUIElement:element];
    
    // If the UI element has both a position and a size
    if (elementPosition && elementSize)
    {
        // Create a new rectangle for the frame
		NSRect topLeftWindowRect;
        
        // Read the value of the UI element's top-left corner into the rectangle's origin
		AXValueGetValue((AXValueRef)elementPosition, kAXValueCGPointType, &topLeftWindowRect.origin);
        
        // Read the value of the UI element's size into the rectangle's size
		AXValueGetValue((AXValueRef)elementSize, kAXValueCGSizeType, &topLeftWindowRect.size);
        
        // Set the bounds based on the screen being flipped
		bounds = [self flippedScreenBounds:topLeftWindowRect];
    }
    
    // Return the frame
    return bounds;
}

#pragma mark -
#pragma mark String Descriptions


/*
 * stringDescriptionOfAXValue: Shortern description strings for some UI element types. 
 * @param CFTypeRef valueRef: A value reference
 *        BOOL beVerbose: Whether to load a full description for elements, or only basic info. 
 * @return NSString*: A string describing the value of the UI element. 
 */
+ (NSString *)stringDescriptionOfAXValue:(CFTypeRef)valueRef beingVerbose:(BOOL)beVerbose
{
    // Initialise the return variable
    NSString *result = @"AXValue???";
    
    // Switch-case to check for particular types
    switch (AXValueGetType(valueRef)) 
    {
            // CGPoint type. Todo: Remove. 
        case kAXValueCGPointType: 
        {
            CGPoint point;
            if (AXValueGetValue(valueRef, kAXValueCGPointType, &point)) 
            {
                if (beVerbose)
                {
                    result = [NSString stringWithFormat:@"<AXPointValue x=%g y=%g>", point.x, point.y];
                } else {
                    result = [NSString stringWithFormat:@"x=%g y=%g", point.x, point.y];
                }
            }
            break;
        }
            
            // CGSize type. Todo: Remove. 
        case kAXValueCGSizeType: {
            CGSize size;
            if (AXValueGetValue(valueRef, kAXValueCGSizeType, &size)) {
                if (beVerbose)
                    result = [NSString stringWithFormat:@"<AXSizeValue w=%g h=%g>", size.width, size.height];
                else
                    result = [NSString stringWithFormat:@"w=%g h=%g", size.width, size.height];
            }
            break;
        }
            
            // CGRect type. Todo: Remove. 
        case kAXValueCGRectType: {
            CGRect rect;
            if (AXValueGetValue(valueRef, kAXValueCGRectType, &rect)) {
                if (beVerbose)
                    result = [NSString stringWithFormat:@"<AXRectValue  x=%g y=%g w=%g h=%g>", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
                else
                    result = [NSString stringWithFormat:@"x=%g y=%g w=%g h=%g", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
            }
            break;
        }
            
            // CFRange type. Todo: Remove. 
        case kAXValueCFRangeType: 
        {
            CFRange range;
            if (AXValueGetValue(valueRef, kAXValueCFRangeType, &range)) 
            {
                if (beVerbose)
                {
                    result = [NSString stringWithFormat:@"<AXRangeValue pos=%ld len=%ld>", range.location, range.length];
                } else {
                    result = [NSString stringWithFormat:@"pos=%ld len=%ld", range.location, range.length];
                }
            }
            break;
        }
            
            // All other types. (What we want)
        default:
            break;
    }
    
    // Return the shorterned description
    return result;
}

/*
 * descriptionOfValue: Get a description string (role and title attributes) of a UI element. 
 * @param CFTypeRef theValue: A value reference
 *        BOOL beVerbose: Whether to load a full description for elements, or only basic info. 
 * @return NSString*: A string describing the role and title of the UI element. 
 */
+ (NSString *)descriptionOfValue:(CFTypeRef)theValue beingVerbose:(BOOL)beVerbose
{
    // Initialise the description string
    NSString *	theValueDescString	= NULL;
    
    // If a type is set
    if (theValue) 
    {
        // If the type is not an illegal type
        if (AXValueGetType(theValue) != kAXValueIllegalType) 
        {
            // Initialise the string using the stringDescriptionOfAXValue method
            theValueDescString = [self stringDescriptionOfAXValue:theValue beingVerbose:beVerbose];
        }
        // If it is an illegal type, but has an array type
        else if (CFGetTypeID(theValue) == CFArrayGetTypeID()) 
        {
            // Return that it is an array, and the number of elements inside
            theValueDescString = [NSString stringWithFormat:@"<array of size %d>", [(NSArray *)theValue count]];
        }
        // If it is an illegal type, and not an array, find the UI element type ID
        else if (CFGetTypeID(theValue) == AXUIElementGetTypeID()) 
        {
            // Initalise the role to null
            NSString *	uiElementRole  	= NULL;
            
            // Try to copy the value attribute
            if (AXUIElementCopyAttributeValue( (AXUIElementRef)theValue, kAXRoleAttribute, (CFTypeRef *)&uiElementRole ) == kAXErrorSuccess) 
            {
                // On successfully getting the value, try to get the title attribute
                NSString *	uiElementTitle  = NULL;
                
                // Try to set the title value to the title attribute
                uiElementTitle = [self valueOfAttribute:NSAccessibilityTitleAttribute ofUIElement:(AXUIElementRef)theValue];
                
#if 0
                // Cocoa app objects don't have titles yet. Use the process ID's application name instead. 
                if (uiElementTitle == nil && [uiElementRole isEqualToString:(NSString *)kAXApplicationRole]) 
                {
                    // Initialise variables for the application's process ID, serial number, and name
                    pid_t				theAppPID = 0;
                    ProcessSerialNumber	theAppPSN = {0,0};
                    NSString *			theAppName = NULL;
                    
                    // If the application can provide the PID, serial number, and name
                    if (AXUIElementGetPid( (AXUIElementRef)theValue, &theAppPID ) == kAXErrorSuccess
                        && GetProcessForPID( theAppPID, &theAppPSN ) == noErr
                        && CopyProcessName( &theAppPSN, (CFStringRef *)&theAppName ) == noErr ) 
                    {
                        // Set the title to the application's name
                        uiElementTitle = theAppName;
                    }
                }
#endif
                
                // If the UI element title is set
                if (uiElementTitle != nil) 
                {
                    // Show both the role and title in the description
                    theValueDescString = [NSString stringWithFormat:@"<%@: “%@”>", uiElementRole, uiElementTitle];
                }
                else {
                    // If the title is not set, just show the role
                    theValueDescString = [NSString stringWithFormat:@"<%@>", uiElementRole];
                }
                
                // Release the role variable
                [uiElementRole release];
            } else {
                // If the value attribute won't copy, just use a description
                theValueDescString = [(id)theValue description];
            }
        } else {
            // If it is an illegal type, but is not an array and has no type, just use a description
            theValueDescString = [(id)theValue description];
        }
    } // end if no type is set
    
    // Return the description string
    return theValueDescString;
}

/*
 * lineageOfUIElement: Return the inheritance of the current UI element as an array. 
 * @param AXUIElementRef element: The UI element
 * @return NSArray* : The inheritance of the current UI element
 */
+ (NSArray *)lineageOfUIElement:(AXUIElementRef)element
{
    // Initialise the return variable
    NSArray *lineage = [NSArray array];
    
    // Get the description of the UI element
    NSString *elementDescr = [self descriptionOfValue:element beingVerbose:NO];
    
    // Find the UI element's parent
    AXUIElementRef parent = (AXUIElementRef)[self valueOfAttribute:NSAccessibilityParentAttribute ofUIElement:element];
    
    // If the parent is set
    if (parent != NULL)
    {
        // Recursively keep adding to the array
        lineage = [self lineageOfUIElement:parent];
    }
    
    // Return the completed inheritance lineage
    return [lineage arrayByAddingObject:elementDescr];
}

/*
 * lineageDescriptionOfUIElement: Return the inheritance of the current UI element as a string. 
 * @param AXUIElementRef element: The UI element
 * @return NSString* : The inheritance of the current UI element
 */
+ (NSString *)lineageDescriptionOfUIElement:(AXUIElementRef)element
{
    // Initialise the return variable
    NSMutableString *result = [NSMutableString string];
    
    // Initialise an indentation layer tracker
    NSMutableString *indent = [NSMutableString string];
    
    // Get the lineage array using the lineageOfUIElement method
    NSArray *lineage = [self lineageOfUIElement:element];
    
    // Start from the highest parent in the lineage array
    NSString *ancestor;
    
    // The enumerator to count through the array
    NSEnumerator *e = [lineage objectEnumerator];
    
    // Progress down the array, from the ancestor to the lowest level
    while (ancestor = [e nextObject]) 
    {
        // Append the indentation to the string
        [result appendFormat:@"%@%@\n", indent, ancestor];
        
        // Add indenting as the lineage gets longer
        [indent appendString:@" "];
    }
    
    // Return the lineage string
    return result;
}

/*
 * stringDescriptionOfUIElement: Get a string value for the current UI element. 
 * @param AXUIElementRef element: The UI element
 * @return NSString*: A string describing the element. 
 */
+ (NSString *)stringDescriptionOfUIElement:(AXUIElementRef)element
{    
    // Initialise the string value and URL string
    NSString *	stringValue = NULL;
    
    // Read AXValue
    stringValue = [self descriptionForUIElement:element attribute:@"AXValue" beingVerbose:false];
    
    // If the AXValue is not set, blank the stringValue
    if (([stringValue rangeOfString:@"null"].location != NSNotFound)) { stringValue = @""; }
    
    // If reading AXValue failed
    if ([stringValue isEqualToString:@""])
    {
        // Read AXHelp
        stringValue = [self descriptionForUIElement:element attribute:@"AXHelp" beingVerbose:false];
    }
    
    // If reading AXHelp failed, blank the stringValue
    if (([stringValue rangeOfString:@"null"].location != NSNotFound)) { stringValue = @""; }
    
    // If reading AXValue and AXHelp failed, read the clipboard
    if ([stringValue isEqualToString:@""])
    {
        // Instantiate a clipboard reader
        NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
        
        // Read the stringValue from the clipboard
        stringValue = [pasteBoard  stringForType:NSPasteboardTypeString];
    }
    
    // If reading the clipboard failed, reset the string to empty. 
    if (([stringValue rangeOfString:@"null"].location != NSNotFound)) { stringValue = @""; }
    
    // Debug prompt
    //    NSLog(@"translating: \"%@\"", stringValue);
    
    // If the string is not blank, return it
    //    if (![stringValue isEqualToString:@""])
    //    {
    //        [theDescriptionStr appendFormat:@"%@", stringValue];
    //        
    //    }
    
    // Return the description string
    return stringValue;
}

/*
 * descriptionForUIElement: Get a description (role and title) for an attribute of the current UI element. 
 * @param AXUIElementRef element: The UI element
 *        NSString* name: The name of a particular attribute to read
 *        BOOL beVerbose: Whether to load a full description for elements, or only basic info. 
 * @return NSString*: A string describing the attribute. 
 */
+ (NSString *)descriptionForUIElement:(AXUIElementRef)uiElement attribute:(NSString *)name beingVerbose:(BOOL)beVerbose
{
    // Initialise the return variable
    NSString *	theValueDescString	= NULL;
    
    // Declare variables for the value type and array item count
    CFTypeRef theValue;
    CFIndex	count;
    
    // If the attribute includes children or rows, and getting the value fails, it is an array
    if (([name isEqualToString:NSAccessibilityChildrenAttribute]
         ||
         [name isEqualToString:NSAccessibilityRowsAttribute]
         )
        &&
        AXUIElementGetAttributeValueCount(uiElement, (CFStringRef)name, &count) == kAXErrorSuccess) {
        
        // Count the number of items in an array, dont't get the values
        theValueDescString = [NSString stringWithFormat:@"<array of size %d>", count];
        
        // If the value can be copied directly
    } else if (AXUIElementCopyAttributeValue ( uiElement, (CFStringRef)name, &theValue ) == kAXErrorSuccess && theValue) {
        
        // Get the description of the UI element using the descriptionOfValue method
        theValueDescString = [self descriptionOfValue:theValue beingVerbose:beVerbose];
    }
    
    // Return the description of the UI element
    return theValueDescString;
}

/*
 * descriptionOfAXDescriptionOfUIElement: Get a description of the AXDescription of the current UI element. 
 * @param AXUIElementRef element: The UI element
 * @return NSString*: A string describing the AXDescription. 
 */
+ (NSString *)descriptionOfAXDescriptionOfUIElement:(AXUIElementRef)element 
{
    // Read the value of an attribute using the valueOfAttribute method
    id result = [self valueOfAttribute:NSAccessibilityDescriptionAttribute ofUIElement:element];
    
    // This method returns a 'no description' string by default, if the value could not be read
    return (!result || [result isEqualToString:@""]) ? UIElementUtilitiesNoDescription: [result description];
}

@end
// end UIElementUtilities implementation