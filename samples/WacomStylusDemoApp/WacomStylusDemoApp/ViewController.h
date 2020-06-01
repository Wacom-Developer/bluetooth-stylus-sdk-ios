/*!--------------------------------------------------------------------------------------------------

 FILE NAME

 ViewController.h

 Abstract: header for the view controller for the application.


 COPYRIGHT
 Copyright WACOM Technology, Inc. 2012-2014
 All rights reserved.

--------------------------------------------------------------------------------------------------*/


#import <UIKit/UIKit.h>
#import "GLKit/GLKView.h"
#import "drawingView.h"
#import <WacomDevice/WacomDeviceFramework.h>
@interface ViewController : UIViewController <UIPopoverPresentationControllerDelegate, WacomDiscoveryCallback, WacomStylusEventCallback>
	
@property (strong, nonatomic) IBOutlet UISegmentedControl *toolBar;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet drawingView *dV;

- (IBAction)SegControlPerformAction:(id)sender;
- (IBAction)showPrivacyMessage:(UIButton *)sender;
- (IBAction)displayHandPositions:(UIButton*)sender;

//WacomDiscoveryCallback

///notification method for when a device is connected.
- (void) deviceConnected:(WacomDevice *)device;

///notification method for when a device is disconnected.
- (void) deviceDisconnected:(WacomDevice *)device;

///notification method for when a device is discovered.
- (void) deviceDiscovered:(WacomDevice *)device;

///notification method for when device discovery is not possible because bluetooth is powered off.
///this allows one to pop up a warning dialog to let the user know to turn on bluetooth.
- (void) discoveryStatePoweredOff;

//WacomStylusEventCallback

///notification method for when a new stylus event is ready.
-(void)stylusEvent:(WacomStylusEvent *)stylusEvent;

@end
