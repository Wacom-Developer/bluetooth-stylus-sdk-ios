/*!--------------------------------------------------------------------------------------------------

 FILE NAME

 drawingView.m

 Abstract: implementation file for the main drawing view of the application.

 COPYRIGHT
 Copyright WACOM Technology, Inc. 2012-2014
 All rights reserved.

 --------------------––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-––-----*/
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "drawingView.h"

#define MIN_BRUSH_SIZE (4.0)
#define THRESHOLD 1.0

#pragma mark -
#pragma mark drawingView (private) declarations
#pragma mark -

@interface drawingView (private)

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;
- (double)calcBrushSize:(double)pressure;
- (void)displayBuffer:(CADisplayLink*)displayLink;
- (void)plotPoints:(NSSet *)touches_I;
- (void)plotTrackedPoints:(NSSet *)touches_I;
- (void)plotLines:(NSSet *)touches_I;
- (void)plotTrackedLines:(NSSet *)touches_I;
- (void)drawTouches:(NSSet *)touches_I withEvent:(UIEvent *)event_I;

@end

#pragma mark -
#pragma mark drawingView
#pragma mark -

@implementation drawingView
{
	CGFloat mPressure;          // Recent pressure vaue from Wacom framwork
	CGFloat mCurrentPressure;   // Current pressure to draw a line
	CGFloat mPreviousPressure;  // Previous pressure value to draw a line
	NSInteger mBrushSize;
	BOOL mEraserSwitchPressed;
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		mPressure = 0.0;
		mCurrentPressure = 0.0;
		mPreviousPressure = 0.0;
	}
	return self;
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder*)coder
{
	if ((self = [super initWithCoder:coder]))
	{
		// Register notifications and view
		[[WacomManager getManager] registerForNotifications:self];
		[[TouchManager GetTouchManager] registerView:self];

		// Sets up the openGL viewport for drawing
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys: // Retain the EAGLDrawable contents after a call to presentRenderbuffer
		[NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		if (!context || ![EAGLContext setCurrentContext:context])
		{
			return nil;
		}

		_initOpenGL = YES;
		mEraserSwitchPressed = NO;

		// Synchronize draw with refresh rate of screen
		_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayBuffer:)];
		[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundNotification:) name:UIApplicationWillResignActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminateNotification:) name:UIApplicationWillTerminateNotification object:[UIApplication sharedApplication]];
	}
	return self;
}

- (void)didEnterBackgroundNotification:(NSNotification *)__unused notification_I
{
	_displayLink.paused = YES;
}

- (void)didEnterForegroundNotification:(NSNotification *)__unused notification_I
{
	_displayLink.paused = NO;
}

- (void)applicationWillTerminateNotification:(NSNotification *)__unused notification_I
{
	[_displayLink invalidate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cleanup
{
	// Unregister view
	[[TouchManager GetTouchManager] unregisterView];
}



////////////////////////////////////////////////////////////////////////////////////////////////////
+ (Class)layerClass
{
	return [CAEAGLLayer class];
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews
{
	[super layoutSubviews];

	if (!_initOpenGL)
	{
		_initOpenGL = YES;
		return;
	}

	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
    
	[self setupBrush:1.0f];
	self.contentScaleFactor = 1.0;
	glClearColor(1.0, 1.0, 1.0, 0.0);
	glMatrixMode(GL_PROJECTION);
	 
	CGRect frame = self.bounds;
	CGFloat scale = self.contentScaleFactor;
	 
	// Setup the view port in pixels
	glLoadIdentity();
	glOrthof(0, frame.size.width * scale, 0, frame.size.height * scale, -1, 1);
	glViewport(0, 0, frame.size.width * scale, frame.size.height * scale);
	glMatrixMode(GL_MODELVIEW);
	 
	glDisable(GL_DITHER);
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_VERTEX_ARRAY);
	 
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	 
	glEnable(GL_POINT_SPRITE_OES);
	glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);

	[self erase];
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setupBrush:(CGFloat)size
{
	// Create a texture from an image
	// First create a UIImage object from the data in a image file, and then extract the Core Graphics image
	CGImageRef brushImage = [UIImage imageNamed:@"Particle.png"].CGImage;
	if (!brushImage)
	{
		return;
	}
	
	// Get the width and height of the image
	size_t width = mBrushSize = CGImageGetWidth(brushImage);
	size_t height = CGImageGetHeight(brushImage);
	
	// Texture dimensions must be a power of 2. If you write an application that allows users to supply an image,
	// you'll want to add code that checks the dimensions and takes appropriate action if they are not a power of 2
	CGFloat lSize = 1.0f;
	GLubyte *brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));                    // Allocate  memory needed for the bitmap context
	CGContextRef brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), (CGBitmapInfo)kCGImageAlphaPremultipliedLast); // Use  the bitmatp creation function provided by the Core Graphics framework
	CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width*lSize, (CGFloat)height*lSize), brushImage); // After you create the context, you can draw the  image to the context
	CGContextRelease(brushContext);		                                                             // You don't need the context at this point, so you need to release it to avoid memory leaks
	glGenTextures(1, &brushTexture);		                                                             // Use OpenGL ES to generate a name for the texture
	glBindTexture(GL_TEXTURE_2D, brushTexture);		                                                 // Bind the texture name
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	                               // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData); // Specify a 2D texture image, providing the a pointer to the image data in memory
	free(brushData);		                                                                            // Release  the image data; it's no longer needed
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)createFramebuffer
{
	// Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);

	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen wherever the layer is (which corresponds with our view)
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);

	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	// We also need a depth buffer so we'll create and attach one via another renderbuffer
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	
	if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}

	[self erase];
	return YES;
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	if (depthRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (double)calcBrushSize:(double)pressure
{
	long maximumPressure = [[[WacomManager getManager] getSelectedDevice] getMaximumPressure];
	double brushSize = MIN_BRUSH_SIZE;
	if (pressure > 0.0)
	{
		double scale = (pressure < THRESHOLD ? maximumPressure : (double)(((maximumPressure-THRESHOLD)+1.0)) / (pressure-THRESHOLD));
		brushSize = mBrushSize / (scale * 3.0);
		if (brushSize < MIN_BRUSH_SIZE)
		{
			brushSize = MIN_BRUSH_SIZE;
		}
	}
	return brushSize;
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)erase
{
	[EAGLContext setCurrentContext:context];
	
	// Clear the buffer
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glClearColor(1.0, 1.0, 1.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)displayBuffer:(CADisplayLink *)displayLink
{
	#pragma unused(displayLink)

	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
	static GLfloat *vertexBuffer = NULL;
	static NSUInteger	vertexMax = 64;
	NSUInteger vertexCount = 0;
	GLint i = 0;
   
	[EAGLContext setCurrentContext:context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);

	// Convert locations from points to pixels
	start.y = self.bounds.size.height - start.y;
	end.y = self.bounds.size.height - end.y;

	CGFloat scale = self.contentScaleFactor;
	start.x *= scale;
	start.y *= scale;
	end.x *= scale;
	end.y *= scale;
	
	// Allocate vertex array buffer
	if (vertexBuffer == NULL)
	{
		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
	}

	// Add points to the buffer so there are drawing points every x pixels
	NSUInteger count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) *3), 1);
	for (i = 0; i < count; ++i)
	{
		if (vertexCount == vertexMax)
		{
			vertexMax = 2 * vertexMax;
			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
		}
		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
		vertexCount += 1;
	}
	
	// Calc brush size
	double fromSize = 0.0;
	double toSize = 0.0;
	if ([[[WacomManager getManager] connectedServices] count] == 0)
	{
		fromSize = toSize = [self calcBrushSize: 0]; // Fixed Brush Size
	}
	else
	{
		fromSize = [self calcBrushSize: mPreviousPressure];
		toSize = [self calcBrushSize: mCurrentPressure];
	}
	
	// Render the vertex array
	glVertexPointer(2, GL_FLOAT, 0, vertexBuffer);
	double size = 0.0;
	for (i = 0; i < count; ++i)
	{
		// Interporlate brush size by linear function.
		size = ((toSize-fromSize)/count)* i + fromSize;
		glPointSize(size);
		glDrawArrays(GL_POINTS, i, 1);
	}
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)plotPoints:(NSSet *)touches_I
{
	glColor4f(1.0, 0.0, 0.0, 0.8);

	for (UITouch *touch in touches_I)
	{
		CGPoint current = [touch locationInView:self];
		[self renderLineFromPoint:current toPoint:current];
	}
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)plotTrackedPoints:(NSSet *)touches_I
{
	glColor4f(0.0, 0.0, 1.0, 0.8);

	NSArray *trackedTouches = [[TouchManager GetTouchManager] getTrackedTouches];
	for (TrackedTouch *trackedTouch in trackedTouches)
	{
		if ([touches_I containsObject:trackedTouch.associatedTouch])
		{
			CGPoint current = trackedTouch.currentLocation;
			[self renderLineFromPoint:current toPoint:current];
		}
	}
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)plotLines:(NSSet *)touches_I
{
	glColor4f(1.0, 0.0, 0.0, 0.1);

	for (UITouch *touch in touches_I)
	{
		CGPoint current = [touch locationInView:self];
		CGPoint previous = [touch previousLocationInView:self];
		[self renderLineFromPoint:previous toPoint:current];
	}
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)plotCoalescedLines:(NSSet *)touches_I withEvent:(UIEvent *)event_I
{
	glColor4f(1.0, 0.0, 0.0, 0.1);
	
	for (UITouch *touch in touches_I)
	{
		for (UITouch *touchCoalesced in [event_I coalescedTouchesForTouch:touch])
		{
			CGPoint current = [touchCoalesced locationInView:self];
			CGPoint previous = [touchCoalesced previousLocationInView:self];
			[self renderLineFromPoint:previous toPoint:current];
		}
	}
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)plotTrackedLines:(NSSet *)touches_I 
{
	mEraserSwitchPressed ? glColor4f(1.0, 1.0, 1.0, 0.0) : glColor4f(0.0, 0.0, 0.0, 0.5);
	
	NSArray *trackedTouches = [[TouchManager GetTouchManager] getTrackedTouches];
	for (TrackedTouch *trackedTouch in trackedTouches)
	{
		if ([touches_I containsObject:trackedTouch.associatedTouch])
		{
			if (mPressure != mCurrentPressure)
			{
				mCurrentPressure = mPressure;
			}

			[self renderLineFromPoint:trackedTouch.previousLocation toPoint:trackedTouch.currentLocation];

			mPreviousPressure = mCurrentPressure;
			mCurrentPressure = mPressure;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)plotCoalescedTrackedLines:(NSSet *)touches_I
{
	glColor4f(0.0, 0.0, 1.0, 0.5);

	NSArray *trackedTouches = [[TouchManager GetTouchManager] getTrackedTouches];
	for (TrackedTouch *trackedTouch in trackedTouches)
	{
		if ([touches_I containsObject:trackedTouch.associatedTouch])
		{
			NSArray *coalescedTrackedTouches = [trackedTouch getCoalescedTrackedTouches];
			for (TrackedTouch *coalescedTrackTouch in coalescedTrackedTouches)
			{
				if (mPressure != mCurrentPressure)
				{
					mCurrentPressure = mPressure;
				}

				[self renderLineFromPoint:coalescedTrackTouch.previousLocation toPoint:coalescedTrackTouch.currentLocation];

				mPreviousPressure = mCurrentPressure;
				mCurrentPressure = mPressure;
			}
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawTouches:(NSSet *)touches_I withEvent:(UIEvent *)event_I
{
	//[self plotLines:touches_I];
	//[self plotCoalescedLines:touches_I withEvent:event_I];
	//[self plotCoalescedTrackedLines:touches_I];
	[self plotTrackedLines:touches_I];
}

#pragma mark -
#pragma mark touchpoint tracking
#pragma mark -

////////////////////////////////////////////////////////////////////////////////////////////////////
// Adding, moving, and removing touches aren't needed if the view is registered
// [[TouchManager GetTouchManager] registerView:self];
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//[[TouchManager GetTouchManager] addTouches:touches view:self event:event];
	mCurrentPressure = mPreviousPressure = mPressure;
}



////////////////////////////////////////////////////////////////////////////////////////////////////
// Adding, moving, and removing touches aren't needed if the view is registered
// [[TouchManager GetTouchManager] registerView:self];
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	//[[TouchManager GetTouchManager] moveTouches:touches view:self event:event];
	[self drawTouches:touches withEvent:event];
}



////////////////////////////////////////////////////////////////////////////////////////////////////
// Adding, moving, and removing touches aren't needed if the view is registered
// [[TouchManager GetTouchManager] registerView:self];
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//[[TouchManager GetTouchManager] moveTouches:touches view:self event:event];
	[self drawTouches:touches withEvent:event];
	//[[TouchManager GetTouchManager] removeTouches:touches view:self event:event];
}



////////////////////////////////////////////////////////////////////////////////////////////////////
// Adding, moving, and removing touches aren't needed if the view is registered
// [[TouchManager GetTouchManager] registerView:self];
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	//[[TouchManager GetTouchManager] removeTouches:touches view:self event:event];
}



////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)stylusEvent:(WacomStylusEvent *)stylusEvent
{
	static UIAlertController* alert1 = nil;
	static UIAlertController* alert = nil;
	
	id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
	if([rootViewController isKindOfClass:[UINavigationController class]])
	{
		rootViewController = ((UINavigationController *)rootViewController).viewControllers.firstObject;
	}
	if([rootViewController isKindOfClass:[UITabBarController class]])
	{
		rootViewController = ((UITabBarController *)rootViewController).selectedViewController;
	}
	
	switch ([stylusEvent getType])
	{
		case eStylusEventType_PressureChange:
			mPressure = [stylusEvent getPressure];
		break;

		case eStylusEventType_ButtonReleased:
		{
			NSString *message = nil;
			switch ([stylusEvent getButton])
			{
				case 2:
				{
					message = @"Button 2 released";
				}
				break;

				case 1:
				{
					message = @"Button 1 released.";
				}
				break;
					
				case 0:
				{
					mEraserSwitchPressed = NO;
				}
				break;

				default:
				break;
			}
			
			if (message != nil)
			{
				alert1 = [UIAlertController alertControllerWithTitle:@"Button Released"
																									message: message
																						  preferredStyle:UIAlertControllerStyleAlert];
				
				UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
																						handler:^(UIAlertAction * action) {alert1 = nil;}];
				
				[alert1 addAction:defaultAction];
				if (alert == nil)
				{
					[rootViewController presentViewController:alert1 animated:YES completion:^(void) {}];
				}
			}
		}
		break;
			
		case eStylusEventType_ButtonPressed:
		{
			NSString *message = nil;
			switch ([stylusEvent getButton])
			{
				case 2:
				{
					message = @"Button 2 clicked";
				}
				break;

				case 1:
				{
					message = @"Button 1 clicked.";
				}
				break;
					
				case 0:
				{
					mEraserSwitchPressed = YES;
				}
				break;

				default:
				break;
			}
			
			if (message != nil)
			{
				alert = [UIAlertController alertControllerWithTitle:@"Button clicked"
																									message: message
																						  preferredStyle:UIAlertControllerStyleAlert];
				
				UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
																						handler:^(UIAlertAction * action) {
																							if (alert1 != nil)
																							{
																								[rootViewController presentViewController:alert1 animated:YES completion:^(void) {}];
																							}
																						}];
				
				[alert addAction:defaultAction];
				[rootViewController presentViewController:alert animated:YES completion:^(void) { }];
			}
		}
		break;

		case eStylusEventType_MACAddressAvaiable:
		break;

		case eStylusEventType_BatteryLevelChanged:
		break;

		default:
		break;
	}
}

@end
