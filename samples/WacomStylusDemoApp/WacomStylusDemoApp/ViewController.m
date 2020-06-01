/*!--------------------------------------------------------------------------------------------------

 FILE NAME

 ViewController.m

 Abstract: implementation for the application.

 COPYRIGHT
 Copyright WACOM Technology, Inc. 2012-2014
 All rights reserved.

 --------------------––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-––-----*/
#import "ViewController.h"
#import "drawingView.h"
#import "DiscoveryPopoverViewController.h"
#import "HandPositionTableViewController.h"

#define BATTERY_PERCENTAGE_SEGMENT 3

@interface ViewController ()

@end

@implementation ViewController
{
	IBOutlet UIButton *ConnectButton;
	DiscoveryPopoverViewController *mDiscoveredTable;
	HandPositionTableViewController *mHandPositionController;
}



////////////////////////////////////////////////////////////////////////////////
// Notes: registers for discovery related callbacks and sets up the window to show discovery
// status and results
- (IBAction)showPopover:(UIView *)sender
{
	if (mDiscoveredTable == nil)
	{
		mDiscoveredTable = [[DiscoveryPopoverViewController alloc] init];
	}
	
	mDiscoveredTable.modalPresentationStyle = UIModalPresentationPopover;
	mDiscoveredTable.view.backgroundColor = [UIColor whiteColor];
	mDiscoveredTable.preferredContentSize = CGSizeMake(280.0, 320.0);
	mDiscoveredTable.popoverPresentationController.sourceView = self.view;
	mDiscoveredTable.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
	mDiscoveredTable.popoverPresentationController.sourceRect = sender.frame;
	mDiscoveredTable.popoverPresentationController.delegate = self;
	[self presentViewController:mDiscoveredTable animated:YES completion:nil];
	
	// Initiates discovery
	[[WacomManager getManager] startDeviceDiscovery];
}



////////////////////////////////////////////////////////////////////////////////
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
	return UIModalPresentationNone;
}



////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
	[super viewDidLoad];
	[[WacomManager getManager] registerForNotifications:self];

	[_toolBar setTitle:@"" forSegmentAtIndex:BATTERY_PERCENTAGE_SEGMENT];
	[_versionLabel setText:[[WacomManager getManager] getSDKVersion]];
	[[TouchManager GetTouchManager] setHandedness:eh_Unknown];
}



////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated
{
	[_dV cleanup];
}



////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}



////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
	[[WacomManager getManager] deregisterForNotifications:self];
}



////////////////////////////////////////////////////////////////////////////////
- (void)toggleTouchRejection
{
	NSString *message = nil;
	
	if ([TouchManager GetTouchManager].touchRejectionEnabled == YES)
	{
		[TouchManager GetTouchManager].touchRejectionEnabled = NO;
	}
	else
	{
		[TouchManager GetTouchManager].touchRejectionEnabled = YES;
	}

	if ([TouchManager GetTouchManager].touchRejectionEnabled == YES)
	{
		message = @"You have turned ON touch rejection.";
	}
	else
	{
		message = @"You have turned OFF touch rejection.";
	}
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Touch Rejection"
																						message:message
																			  preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
																			handler:^(UIAlertAction * action) {}];
	[alert addAction:defaultAction];
	[self presentViewController:alert animated:YES completion:nil];
}



////////////////////////////////////////////////////////////////////////////////
- (IBAction)showPrivacyMessage:(UIButton *)sender
{
	NSString *message = nil;

	message = @"This app does not collect information about its users. Only previous pairings are stored and they are stored locally. This app does not phone home.";
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Privacy Info"
																						message: message
																			  preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
																			handler:^(UIAlertAction * action) {}];
	
	[alert addAction:defaultAction];
	[self presentViewController:alert animated:YES completion:nil];
}



//////////////////////////////////////////////////////////////////////////////
- (IBAction)displayHandPositions:(UIButton *)sender
{
	if (mHandPositionController == nil)
	{
		mHandPositionController = [[HandPositionTableViewController alloc] init];
	}
	
	mHandPositionController.modalPresentationStyle = UIModalPresentationPopover;
	mHandPositionController.view.backgroundColor = [UIColor whiteColor];
	mHandPositionController.preferredContentSize = CGSizeMake(280.0, 360.0);
	mHandPositionController.popoverPresentationController.sourceView = self.view;
	mHandPositionController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
	mHandPositionController.popoverPresentationController.sourceRect = sender.frame;
	mHandPositionController.popoverPresentationController.delegate = self;
	[self presentViewController:mHandPositionController animated:YES completion:nil];
}



////////////////////////////////////////////////////////////////////////////////
- (IBAction)SegControlSetHandedness:(UISegmentedControl *)sender
{
	switch(sender.selectedSegmentIndex)
	{
		case 0:
			[[TouchManager GetTouchManager] setHandedness:eh_Left];
		break;

		case 1:
			[[TouchManager GetTouchManager] setHandedness:eh_Right];
		break;

		default:
		break;
	};
}



////////////////////////////////////////////////////////////////////////////////
// Notes: controls pairing, toggles touch rejection, and erases the screen when the
// segmented control is clicked.
- (IBAction)SegControlPerformAction:(UISegmentedControl *)sender
{
	switch(sender.selectedSegmentIndex)
	{
		case 0:
			[self showPopover:sender];
		break;

		case 1:
			[_dV erase];
		break;

		case 2:
			[self toggleTouchRejection];
		break;

		default:
		break;
	};
}



////////////////////////////////////////////////////////////////////////////////
// Notes: just add the device to the discovered table. demonstrates signal strength
- (void)deviceDiscovered:(WacomDevice *)device
{
	//	NSLog(@"signal strength %i", [device getSignalStrength]);
	[mDiscoveredTable addDevice:device];
}



////////////////////////////////////////////////////////////////////////////////
// Notes: update the device table then dismiss the popover. 
- (void)deviceConnected:(WacomDevice *)device
{
	[mDiscoveredTable updateDevices:device];
	[[TouchManager GetTouchManager] setFilteringEnabled:YES];
}



////////////////////////////////////////////////////////////////////////////////
// Notes: remove the device then dismiss the popover
-(void)deviceDisconnected:(WacomDevice *)device
{
	[mDiscoveredTable removeDevice:device];
	[[TouchManager GetTouchManager] setFilteringEnabled:NO];
	[_toolBar setTitle:@"" forSegmentAtIndex:BATTERY_PERCENTAGE_SEGMENT];
}



////////////////////////////////////////////////////////////////////////////////
// Notes: if the power is off, it pops a warning dialog.
- (void)discoveryStatePoweredOff
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Bluetooth Power"
														message: @"You must turn on Bluetooth in Settings"
														preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
	[alertController addAction:ok];
	[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:YES completion:nil];
}



////////////////////////////////////////////////////////////////////////////////
- (void)stylusEvent:(WacomStylusEvent *)stylusEvent
{
	switch ([stylusEvent getType])
	{
		case eStylusEventType_BatteryLevelChanged:
			if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)])
			{
				NSOperatingSystemVersion ios8_0_1 = (NSOperatingSystemVersion){8, 0, 1};
				if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios8_0_1])
				{
					[_dV setInitOpenGL:NO];
				}
			}

			[_toolBar setTitle:[NSString stringWithFormat:@"%lu%%", [stylusEvent getBatteryLevel] ] forSegmentAtIndex:BATTERY_PERCENTAGE_SEGMENT];
		break;

		default:
		break;
	}
}

@end
