#include "options.h"
#import "SplashScreen.h"


@implementation SplashScreen


- (void) awakeFromNib
{
    {
        WebFrame * mf = [aboutWebView mainFrame];
        
        NSString* resourceURLString = [[[NSBundle mainBundle] resourceURL] absoluteString];
        NSURL *theURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@Splash/about.html",resourceURLString]];
        NSURLRequest * theURLRequest = [NSURLRequest requestWithURL:theURL];
        [mf loadRequest:theURLRequest];;
        
        //TODO - Try to load remotely, and in case if fails, load locally
        
        //theURL = [NSURL URLWithString:@"http://127.0.0.1:8887/about.html"];
        //theURLRequest = [NSURLRequest requestWithURL:theURL];
        //[mf loadRequest:theURLRequest];;
    }
  
    self.window.level = NSFloatingWindowLevel;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	[[self window] center];
	versionType  = 0;
		
	[[self window] setDelegate:self];
	[[self window] setAlphaValue:0.0];
}

- (IBAction)showWindow:(id)sender {[super showWindow:sender];}

- (void) affiche
{
	timerIn = [[NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(fadeIn:) userInfo:nil repeats:YES] retain];
//	[[NSRunLoop currentRunLoop] addTimer:timerIn forMode:NSModalPanelRunLoopMode];
//	[[NSRunLoop currentRunLoop] addTimer:timerIn forMode:NSEventTrackingRunLoopMode];
}

-(id) init {return [super initWithWindowNibName:@"Splash"];}
 
- (BOOL)windowShouldClose:(id)sender
{
	[timerIn invalidate];
	[timerIn release];
	timerIn = nil;
	
    // Set up our timer to periodically call the fade: method.
    timerOut = [[NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(fade:) userInfo:nil repeats:YES] retain];
//	[[NSRunLoop currentRunLoop] addTimer:timerOut forMode:NSModalPanelRunLoopMode];
//	[[NSRunLoop currentRunLoop] addTimer:timerOut forMode:NSEventTrackingRunLoopMode];

//	[timer fire];
	
    // Don't close just yet.
    return NO;
}

- (void)fade:(NSTimer *)theTimer
{
    if ([[self window] alphaValue] > 0.0)
	{
        [[self window] setAlphaValue:[[self window] alphaValue] - 0.1];
    }
	else
	{
        [timerOut invalidate];
        [timerOut release];
        timerOut = nil;
		
        [[self window] close];
    }
}

- (void)fadeIn:(NSTimer *)theTimer
{
	if ([[self window] alphaValue] < 1.0)
	{
        [[self window] setAlphaValue:[[self window] alphaValue] + 0.1];
    }
	else
	{
        [timerIn invalidate];
        [timerIn release];
        timerIn = nil;
		
		[[self window] setAlphaValue:1.0];
    }
}


- (IBAction) opendicomwww:(id) sender
{
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.horosproject.org"]];
}

@end
