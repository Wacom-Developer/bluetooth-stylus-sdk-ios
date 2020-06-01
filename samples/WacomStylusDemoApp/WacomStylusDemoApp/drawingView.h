/*!--------------------------------------------------------------------------------------------------

 FILE NAME

 drawingView.h

 Abstract: Header file for the main drawing view of the application.

 COPYRIGHT
 Copyright WACOM Technology, Inc. 2012-2014
 All rights reserved.

 ----------------------------------------------------------------------------------------------------*/
#import <UIKit/UIKit.h>
#import "GLKit/GLKView.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <WacomDevice/WacomDeviceFramework.h>

@interface drawingView : UIView <WacomStylusEventCallback>
{
@private
	GLint backingWidth;       // The pixel dimensions of the backbuffer
	GLint backingHeight;
	EAGLContext *context;
	GLuint viewRenderbuffer;  // OpenGL names for the renderbuffer used to render to this view
	GLuint viewFramebuffer;   // OpenGL names for the framebuffers used to render to this view
	GLuint depthRenderbuffer; // OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist)
	GLuint brushTexture;
	CADisplayLink *_displayLink;
}

@property BOOL initOpenGL;

- (void)setupBrush:(CGFloat)size;                    // Sets up the brush size based on pressure data
- (void)stylusEvent:(WacomStylusEvent *)stylusEvent; // A callback method for the Wacom SDK that provides pressure data among other things.
- (void)erase;                                       // Clears the screen
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end; // Draws a line between two points
- (void)cleanup;

@end
