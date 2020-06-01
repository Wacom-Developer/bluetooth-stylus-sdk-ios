//
//  HandPositionTableViewController.m
//  WacomStylusDemoApp
//
//  Created by minion on 11/14/14.
//  Copyright (c) 2014 Wacom. All rights reserved.
//

#import "HandPositionTableViewController.h"

@interface HandPositionTableViewController ()

@property (strong) NSDictionary *dictionaryHandPositions;
@property (strong) NSDictionary *dictionaryHandPositionIndexes;
@property (strong) NSDictionary *dictionaryHandPositionImages;

@end

@implementation HandPositionTableViewController
{
	UITableView *mHandPositionTable;
}

////////////////////////////////////////////////////////////////////////////////
- (id)init
{
	self = [super initWithNibName:nil bundle:nil];
	if (self)
	{
		_dictionaryHandPositions = [[NSDictionary alloc] initWithObjectsAndKeys:
											 [NSNumber numberWithInt:eh_Right], @"Right",
											 [NSNumber numberWithInt:eh_RightUpward], @"Right Upward",
											 [NSNumber numberWithInt:eh_RightDownward], @"Right Downward",
											 [NSNumber numberWithInt:eh_Left], @"Left",
											 [NSNumber numberWithInt:eh_LeftUpward], @"Left Upward",
											 [NSNumber numberWithInt:eh_LeftDownward], @"Left Downward",
											  nil];

		_dictionaryHandPositionIndexes = [[NSDictionary alloc] initWithObjectsAndKeys:
													 @"Right", [NSNumber numberWithInt:1],
													 @"Right Upward", [NSNumber numberWithInt:0],
													 @"Right Downward", [NSNumber numberWithInt:2],
													 @"Left", [NSNumber numberWithInt:4],
													 @"Left Upward", [NSNumber numberWithInt:3],
													 @"Left Downward", [NSNumber numberWithInt:5],
													 nil];

		_dictionaryHandPositionImages = [[NSDictionary alloc] initWithObjectsAndKeys:
													[UIImage imageNamed:@"HandPositionRight"], @"Right",
													[UIImage imageNamed:@"HandPositionRightUp"], @"Right Upward",
													[UIImage imageNamed:@"HandPositionRightDown"], @"Right Downward",
													[UIImage imageNamed:@"HandPositionLeft"], @"Left",
													[UIImage imageNamed:@"HandPositionLeftUp"], @"Left Upward",
													[UIImage imageNamed:@"HandPositionLeftDown"], @"Left Downward",
													nil];
	}
	return self;
}



////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	button.frame = CGRectMake(100.0, 0.0, 80.0, 39.0);
	[button setTitle:@"Done" forState:UIControlStateNormal];
	[button addTarget:self action:@selector(buttonPushed) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
	
	UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 39.0, 280.0, 1.0)];
	separator.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1];
	[self.view addSubview:separator];
	
	if (mHandPositionTable == nil)
	{
		CGRect positionTableFrame = CGRectMake(0.0, 40.0, 280.0, 360.0);
		[[self view] setFrame:positionTableFrame];

		mHandPositionTable = [[UITableView alloc] initWithFrame:positionTableFrame style:UITableViewStylePlain];
		[mHandPositionTable setDataSource:self];
		[mHandPositionTable setDelegate:self];
		mHandPositionTable.separatorStyle = UITableViewCellSeparatorStyleNone;
	}
	[self.view addSubview:mHandPositionTable];
	[mHandPositionTable setEditing:NO];
	[mHandPositionTable setBounces:NO];
}



////////////////////////////////////////////////////////////////////////////////
- (void)buttonPushed
{
	[self dismissViewControllerAnimated:YES completion:nil];
}



////////////////////////////////////////////////////////////////////////////////
- (void) viewWillAppear:(BOOL)animated
{
	[mHandPositionTable setRowHeight:50.0];
	[mHandPositionTable reloadData];
	[self.view setNeedsDisplay];
	[super viewWillAppear:animated];
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_dictionaryHandPositions count];
}

////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] init];
	NSString *key = (NSString *)[_dictionaryHandPositionIndexes objectForKey:[NSNumber numberWithInteger:indexPath.row]];
	UIImage *image = (UIImage *)[_dictionaryHandPositionImages objectForKey:key];

	[cell.textLabel setText:key];
	[cell.imageView setImage:image];
	
	int handedness = [[_dictionaryHandPositions objectForKey:key] intValue];
	if (handedness == [[TouchManager GetTouchManager] getHandedness])
	{
		[tableView
		 selectRowAtIndexPath:indexPath
		 animated:TRUE
		 scrollPosition:UITableViewScrollPositionNone
		 ];
		
		[[tableView delegate]
		 tableView:tableView
		 didSelectRowAtIndexPath:indexPath
		 ];
	}
	
	return cell;
}

////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *key = (NSString *)[_dictionaryHandPositionIndexes objectForKey:[NSNumber numberWithInteger:indexPath.row]];
	int handedness = [[_dictionaryHandPositions objectForKey:key] intValue];
	
	[[TouchManager GetTouchManager] setHandedness:handedness];
}

@end
