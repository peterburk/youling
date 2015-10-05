/*
 
 File: AppDelegate.m
 
 Abstract: Main file for the cursor controller.
 
 Version: 1.0
 
 Last updated: 5 January 2012
 Author: Peter Burkimsher
 peterburk@gmail.com
 
 Copyright © 2011 Peterburk
 
 To Do:
 • Google/Bing Translator
 • Offline warning
 • Offline translation option
 
 Done:
 • Comment all code
 • Remove surplus code
 • Combine into a single .xib
 • Translator as a method
 • Interface, not global variables
 • Last line of long text
 • Send on return
 • Several quit keys
 • Preferences window:
 - Show highlight window checkbox
 - Google API key
 - Full language selection
 - Send only translated, or both
 - Disable Powered By message
 */

// Import general libraries
#import <Cocoa/Cocoa.h>
#import <AppKit/NSAccessibility.h>
#import <Carbon/Carbon.h>

// Import application-specific headers
#import "AppDelegate.h"
#import "UIElementUtilities.h"

// Private AppDelegate
@interface AppDelegate (Private)

// Interaction window - Is it visible?
- (BOOL)isInteractionWindowVisible;
@end

#pragma mark Hot Key Registration And Handler
// Interaction window - Create a hot key
EventHotKeyRef	gMyHotKeyRef;
EventHotKeyRef	qMyHotKeyRef;
EventHotKeyRef	cMyHotKeyRef;
EventHotKeyRef	eMyHotKeyRef;

/*
 * LockUIElementHotKeyHandler: Only a single hotkey is registered, so no need to check which hotkey was pressed
 * @param EventHandlerCallRef nextHandler: The next event to process
 *        EventRef theEvent: The hotkey-pressed event
 *        void *userData: Data from the user
 * @return OSStatus: Event processed successfully or not
 *
 */
OSStatus LockUIElementHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData)
{
	EventHotKeyID hotKeyID;
    GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,sizeof(hotKeyID),NULL,&hotKeyID);
    
    if (hotKeyID.id == 1)
    {
        // Launch the app controller with the user data
        AppDelegate *appController = (AppDelegate *)userData;
        
        // Interaction window - Visible?
        if ([appController isInteractionWindowVisible])
        {
            // Interaction window - If closed, unlock the current UI element after 0.1 second delay
            [NSTimer scheduledTimerWithTimeInterval:0.1 target:appController selector:@selector(unlockCurrentUIElement:) userInfo:nil repeats:NO];
            
        } else {
            // Interaction window - If open, lock the current UI element after 0.1 second delay
            [NSTimer scheduledTimerWithTimeInterval:0.1 target:appController selector:@selector(lockCurrentUIElement:) userInfo:nil repeats:NO];
        }
        return noErr;
    }
    
    if (hotKeyID.id == 2)
    {
        // Inspector window - Quit app when closed
        [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0];
    }
    
    // Return that the event was processed successfully
    return noErr;
}

/*
 * RegisterLockUIElementHotKey: Register a hot key and lock/unlock the current UIElement as needed
 * @param void *userInfo: Info from the user
 * @return OSStatus: Event processed successfully or not
 *
 */
static OSStatus RegisterLockUIElementHotKey(void *userInfo) {
    // Inspector window - Create a keyboard event
    EventTypeSpec eventType = { kEventClassKeyboard, kEventHotKeyReleased };
    
    // Inspector window - Install the keyboard event, to call LockUIElementHotKeyHandler
    InstallApplicationEventHandler(NewEventHandlerUPP(LockUIElementHotKeyHandler), 1, &eventType,(void *)userInfo, NULL);
    
    // Use a unique ID for the hotkey
    EventHotKeyID hotKeyID = { 'lYLk', 1 };
    
    // Inspector window - Set the hotkey to Cmd-Option-L
    return RegisterEventHotKey(kVK_ANSI_L, cmdKey+optionKey, hotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);
}

/*
 * RegisterCloseHotKey: Register a hot key to quit the app
 * @param void *userInfo: Info from the user
 * @return OSStatus: Event processed successfully or not
 *
 */
static OSStatus RegisterCloseHotKey(void *userInfo) {
    // Inspector window - Create a keyboard event
    EventTypeSpec eventType = { kEventClassKeyboard, kEventHotKeyReleased };
    
    // Inspector window - Install the keyboard event, to call QuitHotKeyHandler
    InstallApplicationEventHandler(NewEventHandlerUPP(LockUIElementHotKeyHandler), 1, &eventType,(void *)userInfo, NULL);
    
    // Use a unique ID for the hotkey
    EventHotKeyID hotKeyID = { 'cYLk', 2 };
    
    // Inspector window - Set the hotkey to Cmd-Option-Y
    return RegisterEventHotKey(kVK_ANSI_Y, cmdKey+optionKey, hotKeyID, GetApplicationEventTarget(), 0, &cMyHotKeyRef);
}

/*
 * RegisterEscHotKey: Register a hot key to quit the app
 * @param void *userInfo: Info from the user
 * @return OSStatus: Event processed successfully or not
 *
 */
static OSStatus RegisterEscHotKey(void *userInfo) {
    // Inspector window - Create a keyboard event
    EventTypeSpec eventType = { kEventClassKeyboard, kEventHotKeyReleased };
    
    // Inspector window - Install the keyboard event, to call QuitHotKeyHandler
    InstallApplicationEventHandler(NewEventHandlerUPP(LockUIElementHotKeyHandler), 1, &eventType,(void *)userInfo, NULL);
    
    // Use a unique ID for the hotkey
    EventHotKeyID hotKeyID = { 'eYLk', 2 };
    
    // Inspector window - Set the hotkey to Cmd-Option-Y
    return RegisterEventHotKey(kVK_Escape, 0, hotKeyID, GetApplicationEventTarget(), 0, &eMyHotKeyRef);
}

/*
 * RegisterQuitHotKey: Register a hot key to quit the app
 * @param void *userInfo: Info from the user
 * @return OSStatus: Event processed successfully or not
 *
 */
static OSStatus RegisterQuitHotKey(void *userInfo) {
    // Inspector window - Create a keyboard event
    EventTypeSpec eventType = { kEventClassKeyboard, kEventHotKeyReleased };
    
    // Inspector window - Install the keyboard event, to call QuitHotKeyHandler
    InstallApplicationEventHandler(NewEventHandlerUPP(LockUIElementHotKeyHandler), 1, &eventType,(void *)userInfo, NULL);
    
    // Use a unique ID for the hotkey
    EventHotKeyID hotKeyID = { 'qYLk', 2 };
    
    // Inspector window - Set the hotkey to Cmd-Q
    return RegisterEventHotKey(kVK_ANSI_Q, cmdKey, hotKeyID, GetApplicationEventTarget(), 0, &qMyHotKeyRef);
}

NSString* urlString;

#pragma mark -

// Implementation of the AppDelegate controller
@implementation AppDelegate


// Settings window - Values and keys
#define sendOptionsValue @"1"
#define sendOptionsKey @"sendOptions"
#define poweredByValue @"0"
#define poweredByKey @"poweredBy"
#define languagesValue @"en/fr/ko/zh-TW/zh-CN/ja"
#define languagesKey @"languages"

#define debugLog 1

/* 
 * dealloc: Release the window controllers, elements, and close down the program
 */
- (void)dealloc
{
    if (_systemWideElement) CFRelease(_systemWideElement);
    if (_currentUIElement) CFRelease(_currentUIElement);
    [super dealloc];
}

/* 
 * applicationDidFinishLaunching: Application has launched
 * @param NSNotification* note: A notification from the system indicating launch status
 */
- (void)applicationDidFinishLaunching:(NSNotification *)note 
{
    // Make window floating
    //    [window ];
    
    // Is GUI scripting enabled?
    if (!AXAPIEnabled())
    {
        // If it is not, run an AppleScript to enable it. 
		NSAppleScript *enableUIScripting = [[NSAppleScript alloc] initWithSource: @"tell application \"System Events\" to set UI elements enabled to true"];
		[enableUIScripting executeAndReturnError:nil];
    }
	
    
    // Create a file manager to install the keystroke
    NSFileManager *thisFileManager = [NSFileManager defaultManager];
    
    // Find the ~/Library/Services folder
    NSString* servicePath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Services"] stringByAppendingPathComponent:@"ToggleYL.workflow"];
    NSString* pbsPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Preferences"] stringByAppendingPathComponent:@"pbs.plist"];
    
    // Check if the service is installed
    BOOL serviceExists = [thisFileManager fileExistsAtPath:servicePath];
    
    // If no file exists at that location, install it!
    if (!serviceExists)
    {
        // Get the path of the application bundle
        NSString *workflowPathFromApp = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"ToggleYL.workflow"];
        
        [thisFileManager copyItemAtPath:workflowPathFromApp toPath:servicePath error:nil];
        
        // Get the path of the application bundle
        NSString *pbsPathFromApp = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"pbs.plist"];
        
        // Install the keystroke the hard way. If PBS exists, delete it. 
        if ([thisFileManager fileExistsAtPath:pbsPath])
        {
            [thisFileManager removeItemAtPath:pbsPath error:nil];
        }
        
        // Copy the new PBS file to set the keystroke
        [thisFileManager copyItemAtPath:pbsPathFromApp toPath:pbsPath error:nil];
    }
    
    // Inspector window - Create system-wide element
    _systemWideElement = AXUIElementCreateSystemWide();
    
    // Register a hot key - userInfo is self (this app)
    RegisterLockUIElementHotKey((void *)self);
//    RegisterCloseHotKey((void *)self);
//    RegisterQuitHotKey((void *)self);
//    RegisterEscHotKey((void *)self);

    // Inspector window - Open
    [self setupWindow];
    [self indicateUIElementIsLocked:NO];
    
    // Update every 0.1 seconds
    [self performTimerBasedUpdate];
}

#pragma mark -

/* 
 * setCurrentUIElement: Inspector window - Set the current UI element
 * @param AXUIElementRef uiElement: The UI element to observe
 */
- (void)setCurrentUIElement:(AXUIElementRef)uiElement
{
    // Initialise the current UI element from the UI element reference
    [(id)_currentUIElement autorelease];
    _currentUIElement = (AXUIElementRef)[(id)uiElement retain];
}

/* 
 * currentUIElement: Inspector window - Get the current UI element
 * @return AXUIElementRef uiElement: The UI element being observed
 */
- (AXUIElementRef)currentUIElement
{
    return _currentUIElement;
}


#pragma mark -

/* 
 * performTimerBasedUpdate: Inspector window - Update the current UI element after 0.1 seconds
 * @return AXUIElementRef uiElement: The UI element being observed
 */
- (void)performTimerBasedUpdate
{
    // Inspector window - Update the current UI element
    [self updateCurrentUIElement];
    
    // Call the same method again after 0.1 seconds
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(performTimerBasedUpdate) userInfo:nil repeats:NO];
}

/* 
 * updateUIElementInfoWithAnimation: Inspector window - Read properties of the current UI element
 * @param BOOL flag: Whether to animate changing the highlight window
 */
- (void)updateUIElementInfoWithAnimation:(BOOL)flag 
{
    // Inspector window - Get the current UI element
    AXUIElementRef element = [self currentUIElement];
    
    // Inspector window - Update the current properties
    [self updateInfoForUIElement:element];
}


/* 
 * updateCurrentUIElement: Inspector window - Update the current UI element
 */
- (void)updateCurrentUIElement
{
    // Interaction window - If it is not open
    if (_currentlyInteracting == FALSE)
    {
        // The current mouse position with origin at top right.
        NSPoint cocoaPoint = [NSEvent mouseLocation];
        
        // Only ask for the UIElement under the mouse if has moved since the last check.
        if (!NSEqualPoints(cocoaPoint, _lastMousePoint)) 
        {
            // Convert the mouse position to a CG point
            CGPoint pointAsCGPoint = [UIElementUtilities carbonScreenPointFromCocoaScreenPoint:cocoaPoint];
            
            // Initialise a UI element
            AXUIElementRef newElement = NULL;
            
            // Ask Accessibility API for UI Element under the mouse, and check if it has changed
            if (AXUIElementCopyElementAtPosition( _systemWideElement, pointAsCGPoint.x, pointAsCGPoint.y, &newElement ) == kAXErrorSuccess
                && newElement
                && ([self currentUIElement] == NULL || ! CFEqual( [self currentUIElement], newElement ))) 
            {
                // Inspector window - Update current UI element
                [self setCurrentUIElement:newElement];
                [self updateUIElementInfoWithAnimation:NO];
            } // end if ui element changed
            
            // Update the last mouse point location
            _lastMousePoint = cocoaPoint;
            
        } // end if mouse has moved
    } // end if interaction window visible
}

#pragma mark -

/* 
 * isInteractionWindowVisible: Interaction window - Is it open?
 * @return BOOL: Open or closed
 */
- (BOOL)isInteractionWindowVisible
{
    return _currentlyInteracting;
}

/* 
 * lockCurrentUIElement: Hot key pressed. Inspector window - Lock, and Interaction window - Open
 * @param id sender: The calling method
 */
- (IBAction)lockCurrentUIElement:(id)sender
{
    // Interaction window - Set _currentlyInteracting
    _currentlyInteracting = YES;
    
    // Inspector window - Lock
    [self indicateUIElementIsLocked:YES];
    
    NSString* fromLanguage = [_fromLanguage titleOfSelectedItem];
    NSString* toLanguage = [_toLanguage titleOfSelectedItem];
    
//    NSString* translateURL = [[NSString alloc] initWithFormat:@"http://translate.google.com/m/translate?hl=en&vi=m&sl=%@&tl=%@", fromLanguage, toLanguage];
//    
//    [[webTranslator mainFrame] loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:translateURL]]];
}

/* 
 * unlockCurrentUIElement: Interaction window closed. Inspector window - Unlock. 
 * @param id sender: The calling method
 */
- (void)unlockCurrentUIElement:(id)sender
{
    // Set _currentlyInteracting
    _currentlyInteracting = NO;
    
    // Inspector window - Unlock
    [self indicateUIElementIsLocked:NO];
    
    // Inspector window - Bring to front
    [floatingWindow makeKeyAndOrderFront:nil];
    
//    NSString* fromLanguage = [_fromLanguage titleOfSelectedItem];
//    NSString* toLanguage = [_toLanguage titleOfSelectedItem];
//    
//    NSString* translateURL = [[NSString alloc] initWithFormat:@"http://translate.google.com/m/translate?hl=en&vi=m&sl=%@&tl=%@", fromLanguage, toLanguage];
//    
//    [[webTranslator mainFrame] loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:translateURL]]];
}

#pragma mark -

/* 
 * navigateToUIElement: Interaction window - Load path of UI element. 
 * @param id sender: The calling method
 */
- (void)navigateToUIElement:(id)sender
{
    // Interaction window - If open
    if (_currentlyInteracting) 
    {
        // Inspector window - Get current UI element
        AXUIElementRef element = (AXUIElementRef)[sender representedObject];
        
        // If this is an application UI element, animate highlight window
        BOOL flag = ![UIElementUtilities isApplicationUIElement:element];
        flag = flag && ![UIElementUtilities isApplicationUIElement:[self currentUIElement]];
        
        // Inspector window - Set the current UI element
        [self setCurrentUIElement:element];
        
        // Interaction window - Load properties of UI element
        [self updateUIElementInfoWithAnimation:flag];
    }
}

/* 
 * refreshInteractionUIElement: Interaction window - Load path of UI element. 
 * @param id sender: The calling method
 */
- (void)refreshInteractionUIElement:(id)sender
{
    // Interaction window - If open
    if (_currentlyInteracting) 
    {
        // Interaction window - Update properties of UI element
        [self updateUIElementInfoWithAnimation:YES];
    }
}


#pragma mark -

/* 
 * applicationShouldTerminateAfterLastWindowClosed: Inspector window - Quit when closed?
 * @param NSApplication* sender: The calling application
 * @return BOOL: Whether to quit when closed
 */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

/*
 * updateInfoForUIElement: Inspector window - Update text field with the UI element string
 * @param AXUIElementRef element: The current UI element
 */
- (void)updateInfoForUIElement:(AXUIElementRef)element
{
    if (debugLog == TRUE)
    { NSLog(@"updateInfoForUIElement"); }
    
    // The value of the mouse-over item and the translated version
    NSString* stringValue = NULL;
    
    stringValue = [UIElementUtilities stringDescriptionOfUIElement:element];
    
    // Tail the string to the last line
    stringValue = [stringValue stringByReplacingOccurrencesOfString:@"\n" withString:@"/"];
    stringValue = [stringValue lastPathComponent];
    
    // Ask for a translation
    [self translateText:stringValue];
    
    // Set the console view
    [_consoleView setString:stringValue];
}


/*
 * fontSizeSelected: Inspector window - New font size selected from popup menu
 * @param id sender: The calling method
 */
- (IBAction)fontSizeSelected:(id)sender
{
    if (debugLog == TRUE)
    { NSLog(@"fontSizeSelected"); }
    
    // Inspector window - Set console view text size
	[_consoleView setFont:[NSFont userFontOfSize:[[sender titleOfSelectedItem] floatValue]]];
}

/*
 * fromLanguageSelected: Inspector window - New from language selected from popup menu
 * @param id sender: The calling method
 */
- (IBAction)fromLanguageSelected:(id)sender
{
    if (debugLog == TRUE)
    { NSLog(@"fromLanguageSelected"); }
    
    NSString* fromLanguage = [_fromLanguage titleOfSelectedItem];
    NSString* toLanguage = [_toLanguage titleOfSelectedItem];
    
    NSString* translateURL = [[NSString alloc] initWithFormat:@"http://translate.google.cn/m/translate?hl=en&vi=m&tl=%@&sl=%@&q=", toLanguage, fromLanguage];
    
    //[[webTranslator mainFrame] loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:translateURL]]];
    
    NSString *javascriptRequest = [NSString stringWithFormat:@"document.getElementsByTagName('HTML')[0].childNodes[2].childNodes[7].childNodes[0].childNodes[0].childNodes[0].childNodes[0].childNodes[0].childNodes[0].value=\"%@\";", fromLanguage];

    [webTranslator stringByEvaluatingJavaScriptFromString:javascriptRequest];

}

/*
 * toLanguageSelected: Inspector window - New to language selected from popup menu
 * @param id sender: The calling method
 */
- (IBAction)toLanguageSelected:(id)sender
{    
    if (debugLog == TRUE)
    { NSLog(@"toLanguageSelected"); }
    
    NSString* fromLanguage = [_fromLanguage titleOfSelectedItem];
    NSString* toLanguage = [_toLanguage titleOfSelectedItem];
    
    NSString* translateURL = [[NSString alloc] initWithFormat:@"http://translate.google.cn/m/translate?hl=en&vi=m&tl=%@&sl=%@&q=", toLanguage, fromLanguage];
    
//    [[webTranslator mainFrame] loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:translateURL]]];    
            
    NSString *javascriptRequest = [NSString stringWithFormat:@"document.getElementsByTagName('HTML')[0].childNodes[2].childNodes[7].childNodes[0].childNodes[0].childNodes[0]. childNodes[2].childNodes[0].childNodes[0].value=\"%@\";", toLanguage];
    
    [webTranslator stringByEvaluatingJavaScriptFromString:javascriptRequest];
    
}

/*
 * translateText: Get a string value for the current UI element. 
 * @param NSString* stringValue: The string to translate
 *        NSString* fromLanguage: The language to translate from
 *        NSString* toLanguage: The language to translate to
 * @return NSString*: The translated text. 
 */
- (void)translateText:(NSString*)stringValue
{
    if (debugLog == TRUE)
    { NSLog(@"translateText"); }
    
    // Initialise the URL string
    NSString*  urlQueryString = NULL;
    NSString* fromLanguage = NULL;
    NSString* toLanguage = NULL;
    
    fromLanguage = [_fromLanguage titleOfSelectedItem];
    toLanguage = [_toLanguage titleOfSelectedItem];
    
    if ([fromLanguage isEqualToString:@"zh-TW"])
    {
        fromLanguage = @"zh-CN";
    }
    
    // Prepare the URL-ready string
    urlQueryString = stringValue;
    urlQueryString = [urlQueryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    urlQueryString = [urlQueryString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    urlQueryString = [urlQueryString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    urlString = [NSString stringWithFormat:@"http://translate.google.com/m/translate#%@/%@/%@", fromLanguage, toLanguage, urlQueryString];
    
    if (debugLog == TRUE)
    { NSLog(@"urlString: %@", urlString); }
    
    // Ask for a translation
    [webTranslator stopLoading:nil];
    [[webTranslator mainFrame] loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:urlString]]];
    
    
    // From language
    
//    NSString* fromLanguage = [_fromLanguage titleOfSelectedItem];
//    NSString *javascriptRequestFrom = [NSString stringWithFormat:@"document.getElementsByTagName('HTML')[0].childNodes[2].childNodes[7].childNodes[0].childNodes[0].childNodes[0].childNodes[0].childNodes[0].childNodes[0].childNodes[1].value=\"%@\";", fromLanguage];
//    
//    [webTranslator stringByEvaluatingJavaScriptFromString:javascriptRequestFrom];
//    
//    // To language
//    NSString* toLanguage = [_toLanguage titleOfSelectedItem];
//    
//    NSString *javascriptRequestTo = [NSString stringWithFormat:@"document.getElementsByTagName('HTML')[0].childNodes[2].childNodes[7].childNodes[0].childNodes[0].childNodes[0]. childNodes[2].childNodes[0].childNodes[0].childNodes[1].value=\"%@\";", toLanguage];
//    
//    [webTranslator stringByEvaluatingJavaScriptFromString:javascriptRequestTo];
//    
//    // Text
//    NSString *javascriptRequest = [NSString stringWithFormat:@"document.getElementsByTagName('TEXTAREA')[0].value=\"%@\";", stringValue];
//    
//    [webTranslator stringByEvaluatingJavaScriptFromString:javascriptRequest];
//
//    javascriptRequest = @"_e(event,'translate+2');";
//    
//    [webTranslator stringByEvaluatingJavaScriptFromString:javascriptRequest];
//    
//    javascriptRequest = @"document.documentElement.outerHTML;";
//    
//    NSString *jsTranslate = [webTranslator stringByEvaluatingJavaScriptFromString:javascriptRequest];
//    
//    NSArray* thisTextItems = [jsTranslate componentsSeparatedByString:@"<div class=\"translation\">"];
//    
//    NSString* translatedText = [self textBetween:jsTranslate :@"<div class=\"translation\">" :@"</div>"];
//    translatedText = [translatedText stringByReplacingOccurrencesOfString:@"\n" withString:@"/"];
//    translatedText = [translatedText stringByReplacingOccurrencesOfString:@"///" withString:@""];
//
//    if (debugLog == TRUE)
//    { NSLog(@"translatedText: %@", translatedText); }
//    
//    [self sendTranslation:translatedText];
    
    // Progress indicator - Spin
    [spinner setHidden:FALSE];
    [spinner startAnimation:nil];
    
    // Call getTranslation after 0.5 seconds
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(getTranslation) userInfo:nil repeats:NO];
}

- (void)getTranslation
{
    NSString* javascriptRequest = @"document.documentElement.outerHTML;";
//
//    NSString* jsTranslate = [webTranslator stringByEvaluatingJavaScriptFromString:javascriptRequest];

//    NSString* javascriptRequest = @"javascript:thisSource=document.documentElement.outerHTML;start_pos=thisSource.indexOf('%5C%22translation%5C%22%3E')+14;end_pos=thisSource.indexOf('%3C',start_pos);newText=thisSource.substring(start_pos,end_pos);start_old=thisSource.indexOf('%3Cdiv%20class=%5C%22translated%5C%22%3E')+24;end_old=thisSource.indexOf('%3C/div%3E',start_old);oldText=thisSource.substring(start_old,end_old);return%20oldText+%22%20-%20%22+newText;";
//
    NSString* jsTranslate = [webTranslator stringByEvaluatingJavaScriptFromString:javascriptRequest];
//
//    if (debugLog == TRUE)
//    { NSLog(@"jsTranslate: %@", jsTranslate); }

    
    NSString* translatedText = [self textBetween:jsTranslate :@"<div class=\"translation\" style=\"direction:ltr\">" :@"</div>"];

    if (debugLog == TRUE)
    { NSLog(@"translatedText: %@", translatedText); }

    
//    NSString* translatedText = jsTranslate;

    
    if ([translatedText isEqualToString:@""])
    {
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(getTranslation) userInfo:nil repeats:NO];
    } else {
        [spinner stopAnimation:nil];
        [spinner setHidden:TRUE];
        
        if (debugLog == TRUE)
        { NSLog(@"translatedText: %@", translatedText); }
        
        [self sendTranslation:translatedText];
    }
}


- (NSString*)textBetween:(NSString*)thisText :(NSString*)startText :(NSString*)endText
{
//    if (debugLog == TRUE)
//    { NSLog(@"textBetween: %@ %@ %@", thisText, startText, endText); }
    
    NSString* returnText = @"";
    
    NSArray* thisTextItems = [thisText componentsSeparatedByString:startText];
    
    if ([startText isEqualToString:@"start"])
    {
        returnText = thisText;
    } else {
        if ((thisTextItems.count) >= 2)
        {
            returnText = [thisTextItems objectAtIndex:1];
        } else {
            returnText = @"";
            
            return returnText;
        }
    }
    
    if ([returnText isEqualToString:@"end"])
    {
        return returnText;
    } else {
        thisTextItems = [returnText componentsSeparatedByString:endText];
        returnText = [thisTextItems objectAtIndex:0];
    }
    
    return returnText;
}

/*
 * indicateUIElementIsLocked: Inspector window - Change text field font colour if locked
 * @param id sender: The calling method
 */
- (void)indicateUIElementIsLocked:(BOOL)flag
{    
    if (debugLog == TRUE)
    { NSLog(@"indicateUIElementIsLocked"); }
    
    // Inspector window - Set text field text colour to red if locked, black if not
	[_consoleView setTextColor:(flag)?[NSColor blueColor]:[NSColor blackColor]];
    
    // Show or hide send button
    [sendButton setHidden:!flag];
    
    if (flag == TRUE)
    {
        // Clear the value of the text field
        [_consoleView setString:@""];
    }
    
    // Swap To and From languages
    NSInteger previousFromLanguageItem = [_fromLanguage indexOfSelectedItem];
    NSInteger previousToLanguageItem = [_toLanguage indexOfSelectedItem];
    
    [_fromLanguage selectItemAtIndex:previousToLanguageItem];
    [_toLanguage selectItemAtIndex:previousFromLanguageItem];
}

/*
 * readUIElementIsLocked: Inspector window - Is the interface locked?
 * @param id sender: The calling method
 */
- (BOOL)readUIElementIsLocked
{
    if (debugLog == TRUE)
    { NSLog(@"readUIElementIsLocked"); }
    
    // Read the locked value from the send button's visiblity
    return [sendButton isHidden];
}

/*
 * sendButtonClicked: Send button was clicked
 * @param id sender: The calling method
 */
- (IBAction)sendButtonClicked:(id)sender;
{
    if (debugLog == TRUE)
    { NSLog(@"sendButtonClicked"); }
    
    // Interaction window - Read the text input field
    NSString *stringValue = [_consoleView string];
    
    // Tail the string to the last line
    stringValue = [stringValue stringByReplacingOccurrencesOfString:@"\n" withString:@"/"];
    stringValue = [stringValue lastPathComponent];
    
    [self translateText:stringValue];
}

/*
 * prefsButtonClicked: Preferences button was clicked
 * @param id sender: The calling method
 */
- (IBAction)prefsButtonClicked:(id)sender;
{
    if (debugLog == TRUE)
    { NSLog(@"prefsButtonClicked"); }
    
    //    [_consoleView setString:@"preferences not yet implemented"];
    
    // Disable repeated pressing
    [prefsButton setEnabled:FALSE];
    
    // Read the current mode
    BOOL currentMode;
    currentMode = [prefsMode isHidden];
    
    // If we are going to the preferences mode
    if (currentMode == TRUE)
    {
        [self readPreferences];
    }
    
    // If we are coming from the preferences mode
    if (currentMode == FALSE)
    {
        [self writePreferences];
    }
    
    // Enable normal pressing
    [prefsButton setEnabled:TRUE];
    
    // Toggle the mode between preferences and view
    [prefsMode setHidden:!currentMode];
    [viewMode setHidden:currentMode];
}

-(void)readPreferences
{
    // Read user settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Read the send option preference
    NSString *sendOptionsSetting = [defaults stringForKey:sendOptionsKey];
    
    // Send: Choose "Text - Translation - Powered By"
    if ([sendOptionsSetting isEqualToString:@"0"])
    { [sendOptions setState:1 atRow:0 column:0]; }
    
    // Send: Choose "Translation - Powered By"
    if ([sendOptionsSetting isEqualToString:@"1"])
    { [sendOptions setState:1 atRow:1 column:0]; }
    
    // Read the powered by preference
    NSString *poweredBySetting = [defaults stringForKey:poweredByKey];
    
    if ([poweredBySetting isEqualToString:@"1"])
    { [hidePoweredBy setState:1]; } else { [hidePoweredBy setState:0]; }
    
    // Read the languages preference
    NSString *languagesSetting = [defaults stringForKey:languagesKey];
    
    if (debugLog == TRUE)
    { NSLog(@"reading languagesSetting: %@", languagesSetting); }
    
    // Use default languages if none are set
    if (languagesSetting == NULL)
    {
        languagesSetting = languagesValue;
        if (debugLog == TRUE)
        { NSLog(@"default languagesSetting: %@", languagesSetting); }
    }
    
    NSArray* languagesArray = [languagesSetting componentsSeparatedByString:@"/"];
    NSInteger currentLanguage;
    NSString* thisLanguage;
    
    // Add languages from preferences
    for (currentLanguage = 0; currentLanguage < languagesArray.count; currentLanguage++)
    {
        thisLanguage = [languagesArray objectAtIndex:currentLanguage];
        
        if (![thisLanguage isEqualToString:@""])
        {
            if (![[languagesComboBox objectValues] containsObject:thisLanguage])
            {
                // Add the item to the end
                [languagesComboBox addItemWithObjectValue:thisLanguage];
            }
        }
    }
    
    // Remove default languages
    [_fromLanguage removeAllItems];
    [_toLanguage removeAllItems];
    
    languagesArray = [languagesComboBox objectValues];
    
    [_fromLanguage addItemsWithTitles:languagesArray];
    [_toLanguage addItemsWithTitles:languagesArray];
}

-(void)writePreferences
{
    // Read user settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Settings window - get the value of the send options radio button
    NSString *sendOption = [NSString stringWithFormat:@"%d", [sendOptions selectedRow]];
    
    // Set the preference to show or hide the Get Started popup
    [defaults setObject:sendOption forKey:sendOptionsKey];
    
    // Settings window - get the value of the powered by checkbox
    NSString* poweredByOption = [NSString stringWithFormat:@"%d", (int)[hidePoweredBy state]];
    
    // Set the preference to show or hide the Get Started popup
    [defaults setObject:poweredByOption forKey:poweredByKey];
    
    NSArray* languagesArray = [languagesComboBox objectValues];
    
    NSInteger currentLanguage;
    NSString* thisLanguage;
    NSString *languagesSetting = @"";
    
    // Add languages from preferences
    for (currentLanguage = 0; currentLanguage < languagesArray.count; currentLanguage++)
    {
        thisLanguage = [languagesArray objectAtIndex:currentLanguage];
        
        // Add the item to the end
        languagesSetting = [NSString stringWithFormat:@"%@/%@", languagesSetting, thisLanguage];
    }
    
    if (debugLog == TRUE)
    { NSLog(@"writing languagesSetting: %@", languagesSetting); }
    
    // Set the languages preference
    [defaults setObject:languagesSetting forKey:languagesKey];
    
}


// Inspector window - Sending options clicked
- (IBAction)sendOptionsEdited:(id)sender
{
    if (debugLog == TRUE)
    { NSLog(@"sendOptionsEdited"); }
}

// Inspector window - Serial number clicked
- (IBAction)serialNumberEdited:(id)sender
{
    if (debugLog == TRUE)
    { NSLog(@"serialNumberEdited"); }
}

// Inspector window - Langauges combo box typed
- (IBAction)languagesComboBoxEdited:(id)sender
{
    if (debugLog == TRUE)
    { NSLog(@"languagesComboBoxEdited"); }
    
    NSString* thisLanguage = [languagesComboBox stringValue];
    
    if ([[languagesComboBox objectValues] containsObject:thisLanguage])
    {
        // Select the item with that value
        [languagesComboBox selectItemWithObjectValue:thisLanguage];
    } else {
        // Add the item to the end
        [languagesComboBox addItemWithObjectValue:[languagesComboBox stringValue]];
    }
    
    // Remove previous languages
    [_fromLanguage removeAllItems];
    [_toLanguage removeAllItems];
    
    NSArray* languagesArray = [languagesComboBox objectValues];
    
    //    [_fromLanguage addItemWithTitle:@"Auto"];
    [_fromLanguage addItemsWithTitles:languagesArray];
    
    //    [_fromLanguage selectItemWithTitle:@"Auto"];
    
    [_toLanguage addItemsWithTitles:languagesArray];
}

// Inspector window - Langauge remove button clicked
- (IBAction)languagesRemoveButtonClicked:(id)sender
{
    if (debugLog == TRUE)
    { NSLog(@"languagesRemoveButtonClicked"); }
    
    // Remove the currently selected item
    [languagesComboBox removeItemWithObjectValue:[languagesComboBox stringValue]];
    
    // Select the first item in the list
    [languagesComboBox selectItemAtIndex:0];
}

/*
 * setupWindow: Inspector window - Initialise app when opened
 * @param NSNotification* note: The window will open notification
 */
- (void)setupWindow
{
    if (debugLog == TRUE)
    { NSLog(@"setupWindow"); }
    
    [webTranslator setFrameLoadDelegate:self]; 
    
    // Show the preferences button
    [prefsButton setHidden:NO];
    [floatingWindow setTitlebarAccessoryView:prefsButton];
    
    // Inspector window - Set console view text size
	[_consoleView setFont:[NSFont userFontOfSize:12]];
    
    // Inspector window - Set size
    NSRect viewModeFrame = [viewMode frame];
    [prefsMode setFrame:viewModeFrame];
    [prefsMode setHidden:TRUE];
    
    [webTranslator setFrameLoadDelegate:self];
    
    // Setup preferences
    [self readPreferences];
    
    [_fromLanguage selectItemAtIndex:0];
    [_toLanguage selectItemAtIndex:1];
    
    // Inspector window - Float
    [floatingWindow setLevel:CGWindowLevelForKey(kCGFloatingWindowLevelKey)];
    
    NSString* fromLanguage = [_fromLanguage titleOfSelectedItem];
    NSString* toLanguage = [_toLanguage titleOfSelectedItem];
    
    NSString* translateURL = [[NSString alloc] initWithFormat:@"http://translate.google.com/m/translate?hl=en&vi=m&sl=%@&tl=%@", fromLanguage, toLanguage];
    
    [[webTranslator mainFrame] loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:translateURL]]];

    
    // Inspector Window - Unlock when closed
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
    [nc addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:_consoleView];
}

- (void)textDidChange:(NSNotification *)pNotification
{
    if (debugLog == TRUE)
    { NSLog(@"textDidChange"); }
    
    // If the string contains return, send it!
	if ([[_consoleView string] rangeOfString:@"\n"].location != NSNotFound)
    {
        // Click the send button
        [sendButton performClick:nil];
        
        // Clear the text
        [_consoleView setString:[[_consoleView string] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
    }
} // end textDidChange


/*
 * windowWillClose: Inspector window - Quit app when closed
 * @param NSNotification* note: The window will close notification
 */
- (void)windowWillClose:(NSNotification *)note 
{    
    if (debugLog == TRUE)
    { NSLog(@"windowWillClose"); }
    
    // Inspector window - Quit app when closed
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame*)frame
{
    if (debugLog == TRUE)
    { NSLog(@"webview loaded"); }
    
    // Progress indicator - Stop spinning
    [spinner stopAnimation:nil];
    [spinner setHidden:TRUE];
    
//    NSString* javascriptRequest = @"document.documentElement.outerText;";
//    
//    NSString* jsTranslate = [webTranslator stringByEvaluatingJavaScriptFromString:javascriptRequest];
//    
//    NSString* translatedText = [jsTranslate stringByReplacingOccurrencesOfString:@"\n" withString:@"/"];
//    
//    translatedText = [translatedText stringByReplacingOccurrencesOfString:@"Translate//" withString:@""];
//    translatedText = [translatedText stringByReplacingOccurrencesOfString:@"»" withString:@""];    
//    translatedText = [translatedText stringByReplacingOccurrencesOfString:@"/History" withString:@""];
//    translatedText = [translatedText stringByReplacingOccurrencesOfString:@"View: Mobile | Classic" withString:@""];
//    translatedText = [translatedText stringByReplacingOccurrencesOfString:@"©2011 Google  -  Help & Terms" withString:@""];
//    
//    translatedText = [translatedText stringByReplacingOccurrencesOfString:@"///" withString:@""];
//    
//    NSArray* translatedLines = [translatedText componentsSeparatedByString:@"/"];
//    
//    translatedText = @"";
//    
//    int currentLine = 0;
//    
//    // Find the first non-blank line
//    while ([translatedText isEqualToString:@""])
//    {
//        translatedText = [translatedLines objectAtIndex:currentLine];
//        currentLine = currentLine + 1;
//    }
//    
//    if (debugLog == TRUE)
//    { NSLog(@"translatedText: %@", translatedText); }
//    
//    [self sendTranslation:translatedText];
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame 
{
    if (debugLog == TRUE)
    { NSLog(@"webview title"); }
}

-(void)sendTranslation:(NSString*) translatedText
{
    if (debugLog == TRUE)
    { NSLog(@"sendTranslation"); }
    
    NSString* fromLanguage = NULL;
    NSString* toLanguage = NULL;
    
    NSString* stringValue = [_consoleView string];
    
    if ([stringValue isEqualToString:@""])
    {
        return;
    }
    
    if ([sendButton isHidden] == TRUE)
    {
        if (debugLog == TRUE)
        { NSLog(@"send button hidden"); }
        
        fromLanguage = [_fromLanguage titleOfSelectedItem];
        toLanguage = [_toLanguage titleOfSelectedItem];
        
        stringValue = [self textBetween:stringValue :@"start" :@" - \""];
        
        // Combine both the string value and translated version
        stringValue = [NSString stringWithFormat:@"%@ - \"%@\"", stringValue, translatedText];
        
        // Set the value of the text field to the string description of the current UI element
        [_consoleView setString:stringValue];
    }
    
    if ([sendButton isHidden] == FALSE)
    {
        if (debugLog == TRUE)
        { NSLog(@"send button visible"); }
        
        // Inspector window - The current UI element
        AXUIElementRef element = [(id)[NSApp delegate] currentUIElement];
        
        NSString *attributeName = @"AXValue";
        
        // Read user settings
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // Read the send option preference
        NSString *sendOptionsSetting = [defaults stringForKey:sendOptionsKey];
        
        // If the save option value isn't set, use the default
        if (sendOptionsSetting == nil)
        {
            sendOptionsSetting = sendOptionsValue;
        }
        
        if ([sendOptionsSetting isEqualToString:@"0"])
        {
            // Combine both the string value and translated version
            stringValue = [NSString stringWithFormat:@"%@ - ", stringValue];
        }
        
        if ([sendOptionsSetting isEqualToString:@"1"])
        {
            // Combine both the string value and translated version
            stringValue = [NSString stringWithFormat:@"%@", stringValue];
        }
        
        // Read the send option preference
        NSString *poweredByOption = [defaults stringForKey:poweredByKey];
        
        // Combine both the string value and translated version
        stringValue = [NSString stringWithFormat:@"%@\"%@\"", stringValue, translatedText];
        
        if ([poweredByOption isEqualToString:@"0"])
        {
            // Add the unlicensed message
            stringValue = [NSString stringWithFormat:@"%@ - Powered by YouLing", stringValue];
        }
        
        // Interaction window - Set the UI element's AXValue
        [UIElementUtilities setStringValue:stringValue forAttribute:attributeName ofUIElement:element];
        
        // Clear the text
        [_consoleView setString:@""];
    } // end if sendbutton
}
@end
// end AppDelegate implementation
