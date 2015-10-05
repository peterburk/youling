/*
 
 File: AppDelegate.h
 
 Abstract: Header file for the cursor controller.
 
 Version: 1.0
 
 Last updated: 4 October 2011
 Author: Peter Burkimsher
 peterburk@gmail.com
 
 Copyright © 2011 YGuoren
 
 */

// Import necessary libraries
#import <Cocoa/Cocoa.h>
#import <HIServices/Accessibility.h>
#import <WebKit/WebKit.h>
#import "AVPanel.h"

// Global variables for from and to langauge
extern NSString * inspectorFromLanguage;
extern NSString * inspectorToLanguage;

// Interface for the AppDelegate controller
@interface AppDelegate : NSObject {
    // Inspector window - The current UI element, system-wide
    AXUIElementRef			    _systemWideElement;
    
    // Inspector window - The current cursor location
    NSPoint				    _lastMousePoint;
    
    // Inspector window - The current UI element hovered over
    AXUIElementRef			    _currentUIElement;
    
    // Interaction window - Flag to lock the mouseover during interaction
    BOOL				    _currentlyInteracting;
    
    // Interaction window - Highlight option
    BOOL				    _highlightLockedUIElement;
    
    // Inspector window - Text view
    IBOutlet NSTextView * _consoleView;
    
    // Inspector window - From and to language popup buttons
    IBOutlet NSPopUpButton *	_fromLanguage;
    IBOutlet NSPopUpButton *	_toLanguage;
    
    // Inspector window
    IBOutlet AVPanel *floatingWindow;
    IBOutlet NSView *floatingWindowView;
    
    // Inspector window - Send button
    IBOutlet NSButton *sendButton;
    
    // Inspector window - Preferences button
    IBOutlet NSButton *prefsButton;
    
    // View mode and Preferences mode
    IBOutlet NSView *viewMode;
    IBOutlet NSView *prefsMode;
    IBOutlet NSBox *prefsBox;
    
    // Settings
    IBOutlet NSMatrix *sendOptions;
    IBOutlet NSTextField *serialNumber;
    IBOutlet NSButton *hidePoweredBy;
    IBOutlet NSPopUpButton *translatorPopUp;
    IBOutlet NSComboBox *languagesComboBox;
    IBOutlet NSButton *cacheCheckbox;
    
    // Progress indicator
    IBOutlet NSProgressIndicator *spinner;
    
    // Web viewer
    IBOutlet WebView *webTranslator;
}

// Inspector window - Set current UI element
- (void)setCurrentUIElement:(AXUIElementRef)uiElement;

// Inspector window - Get current UI element
- (AXUIElementRef)currentUIElement;

// Inspector window - Update inspector based on timer
- (void)performTimerBasedUpdate;

// Inspector window - Update inspector
- (void)updateCurrentUIElement;

// Interaction window - Lock on the current UI element
- (IBAction)lockCurrentUIElement:(id)sender;

// Interaction window - Unlock from the UI element, and inspect as normal
- (void)unlockCurrentUIElement:(id)sender;

// Inspector window - Find the path to a particular element
- (IBAction)navigateToUIElement:(id)sender;

// Interaction window - Refresh the interaction value
- (IBAction)refreshInteractionUIElement:(id)sender;


// Inspector window - Update the current properties
- (void)updateInfoForUIElement:(AXUIElementRef)uiElement;

// Inspector window - Change colour when locked on a UI element
- (void)indicateUIElementIsLocked:(BOOL)flag;
- (BOOL)readUIElementIsLocked;

// Inspector window - Font size popup selected
- (IBAction)fontSizeSelected:(id)sender;

// Inspector window - From language popup selected
- (IBAction)fromLanguageSelected:(id)sender;

// Inspector window - To language popup selected
- (IBAction)toLanguageSelected:(id)sender;

// Inspector window - Send button clicked
- (IBAction)sendButtonClicked:(id)sender;

// Inspector window - Preferences button clicked
- (IBAction)prefsButtonClicked:(id)sender;

// Inspector window - Sending options clicked
- (IBAction)sendOptionsEdited:(id)sender;

// Inspector window - Serial number clicked
- (IBAction)serialNumberEdited:(id)sender;

// Inspector window - Langauges combo box typed
- (IBAction)languagesComboBoxEdited:(id)sender;

// Inspector window - Langauge remove button clicked
- (IBAction)languagesRemoveButtonClicked:(id)sender;

// Translate the stringValue text from fromLanguage to toLanguage
- (void)translateText:(NSString*)stringValue;

// Setup interface values
-(void)setupWindow;
-(void)readPreferences;
-(void)writePreferences;
-(void)sendTranslation:(NSString*) translatedText;
- (void)getTranslation;
- (NSString*)textBetween:(NSString*)thisText :(NSString*)startText :(NSString*)endText;

@end
