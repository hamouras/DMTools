//
// MBProgressHUD.m
// Version 0.1
// Created by Matej Bukovinski on 8.4.09.
//

#import "MBProgressHUD.h"


@interface MBProgressHUD ()

- (void)hideUsingAnimation:(BOOL)animated;
- (void)showUsingAnimation:(BOOL)animated;

- (void)fillRoundedRect:(CGRect)rect inContext:(CGContextRef)context;

- (void)done;

@property (assign) float width;
@property (assign) float height;

@end



@implementation MBProgressHUD

@synthesize delegate;
@synthesize labelText;
@synthesize detailsLabelText;
@synthesize opacity;
@synthesize labelFont;
@synthesize detailsLabelFont;

@synthesize width;
@synthesize height;


#pragma mark Build up

#define MARGIN 20.0
#define PADDING 4.0

#define LABELFONTSIZE 20.0
#define LABELDETAILSFONTSIZE 16.0

- (id)initWithWindow:(UIWindow* )window {
	return [self initWithFrame:window.bounds];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]) != nil) {
		// Set default values for properties
		self.labelText = @"";
		self.detailsLabelText = @"";
		self.opacity = 0.9;
		self.labelFont = [UIFont boldSystemFontOfSize:LABELFONTSIZE];
		self.detailsLabelFont = [UIFont boldSystemFontOfSize:LABELDETAILSFONTSIZE];
		
		// Transparent background
        self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		
		// Make invisible for now
		self.alpha = 0.0;
		
		// Add indicator subview
		indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		
		// Add label
		label = [[UILabel alloc] initWithFrame:self.bounds];
		
		// Add details label
		detailsLabel = [[UILabel alloc] initWithFrame:self.bounds];
    }
    return self;
}

- (void)layoutAndStyle {
	
	CGRect frame = self.bounds;
	
	// Compute HUD dimensions based on indicator size (add margin to HUD border)
	CGRect indFrame = indicator.bounds;
	self.width = indFrame.size.width + 2*MARGIN;
	self.height = indFrame.size.height + 2*MARGIN;
	
	// Center the indicator
	indFrame.origin.x = (frame.size.width-indFrame.size.width)/2;
	indFrame.origin.y = (frame.size.height-indFrame.size.height)/2;
	indicator.frame = indFrame;
	
	[indicator startAnimating];
	[self addSubview:indicator];
	
	// Add label if label text was set
	if (![self.labelText isEqualToString:@""]) {
		
		// Get size of label text
		CGSize dims = [self.labelText sizeWithAttributes:@{NSFontAttributeName:self.labelFont}];
		
		// Compute label dimensions based on font metrics
		// if size is larger than max then clip the label width
		float lHeight = dims.height;
		float lWidth;
		if (dims.width <= (frame.size.width - 2*MARGIN))
			lWidth = dims.width;
		else
			lWidth = frame.size.width - 4*MARGIN;
		
		// Set label porperties
		label.font = self.labelFont;
		label.adjustsFontSizeToFitWidth = NO;
		label.textAlignment = NSTextAlignmentCenter;
		label.opaque = NO;
		label.backgroundColor = [UIColor clearColor];
		label.textColor = [UIColor whiteColor];
		label.text = self.labelText;
		
		// Update HUD size
		if (self.width < (lWidth + 2*MARGIN))
			self.width = lWidth + 2*MARGIN;
		self.height = self.height + lHeight + PADDING;
		
		// Move indicator to make room for the label
		indFrame.origin.y -= (lHeight/2 + PADDING/2);
		indicator.frame = indFrame;
		
		// Set the label position and dimensions
		CGRect lFrame = CGRectMake((frame.size.width-lWidth)/2, indFrame.origin.y + indFrame.size.height + PADDING, lWidth, lHeight);
		label.frame = lFrame;
		
		[self addSubview:label];
		
		// Add details label delatils text was set
		if (![self.detailsLabelText isEqualToString:@""]) {
			
			// Get size of label text
			dims = [self.detailsLabelText sizeWithAttributes:@{NSFontAttributeName:self.detailsLabelFont}];
			
			// Compute label dimensions based on font metrics
			// if size is larger than max then clip the label width
			lHeight = dims.height;
			if (dims.width <= (frame.size.width - 2*MARGIN))
				lWidth = dims.width;
			else
				lWidth = frame.size.width - 4*MARGIN;
			
			// Set label properties
			detailsLabel.font = self.detailsLabelFont;
			detailsLabel.adjustsFontSizeToFitWidth = NO;
			detailsLabel.textAlignment = NSTextAlignmentCenter;
			detailsLabel.opaque = NO;
			detailsLabel.backgroundColor = [UIColor clearColor];
			detailsLabel.textColor = [UIColor whiteColor];
			detailsLabel.text = self.detailsLabelText;
			
			// Update HUD size
			if (self.width < lWidth)
				self.width = lWidth + 2*MARGIN;
			self.height = self.height + lHeight + PADDING;
			
			// Move indicator to make room for the new label
			indFrame.origin.y -= (lHeight/2 + PADDING/2);
			indicator.frame = indFrame;
			
			// Move first label to make room for the new label
			lFrame.origin.y -= (lHeight/2 + PADDING/2);
			label.frame = lFrame;
			
			// Set label position and dimensions
			CGRect lFrameD = CGRectMake((frame.size.width-lWidth)/2, lFrame.origin.y + lFrame.size.height + PADDING, lWidth, lHeight);
			detailsLabel.frame = lFrameD;
			
			[self addSubview:detailsLabel];
			if (cancelControl)
			{
				detailsLabel.textColor = [UIColor grayColor];
				cancelControl.frame = lFrameD;
				[self addSubview:cancelControl];
			}
		}
	}
}

#pragma mark Showing and execution

- (void) show:(BOOL)animated {
	[self layoutAndStyle];
	[self setNeedsDisplay];
	
	[self showUsingAnimation:animated];
}

- (void) hide:(BOOL)animated {
	[self hideUsingAnimation:animated];
}

- (void)showWhileExecuting:(SEL)method onTarget:(id)target withObject:(id)object animated:(bool)animated {
	
	[self layoutAndStyle];
	[self setNeedsDisplay];
	
	methodForExecution = method;
	targetForExecution = [target retain];
	objectForExecution = [object retain];
	useAnimation = animated;
	
	// Show HUD view
	[self showUsingAnimation:useAnimation];
	
	// Launch execution in new thread
	[NSThread detachNewThreadSelector:@selector(launchExecution) toTarget:self withObject:nil];
}

- (void)launchExecution {
	@autoreleasepool {
		// Start executing the requested task
		[targetForExecution performSelector:methodForExecution withObject:objectForExecution];
		
		// Task completed, update view in main thread (note: view operations should be done only in the main thread)
		[self performSelectorOnMainThread:@selector(cleanUp) withObject:nil waitUntilDone:NO];
	}
}

- (void)animationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	[self done];
}

- (void)done {
	// If delegate was set make the callback
	if (delegate != nil)
	{
		if ([delegate respondsToSelector:@selector(hudWasHidden:)]) {
			[delegate hudWasHidden:self];
		} else {
			[NSException raise:NSInternalInconsistencyException format:@"Delegate doesn't respond to hudWasHidden:"];
		}
	}
}

- (void)cleanUp {
	[targetForExecution release];
	[objectForExecution release];
	
	[self hideUsingAnimation:useAnimation];
}

#pragma mark Fade in and Fade out

- (void)showUsingAnimation:(BOOL)animated {
	// Fade in
	if (animated) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.40];
		self.alpha = 1.0;
		[UIView commitAnimations];
	} else {
		self.alpha = 1.0;
	}
}

- (void)hideUsingAnimation:(BOOL)animated {
	// Fade in
	if (animated) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.40];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationFinished: finished: context:)];
		self.alpha = 0.0;
		[UIView commitAnimations];
	} else {
		self.alpha = 0.0;
		[self done];
	}
}

#pragma mark BG Drawing

- (void)drawRect:(CGRect)rect {
	// Center HUD
	CGRect allRect = self.bounds;
	// Draw rounded HUD bacgroud rect
	CGRect boxRect = CGRectMake((allRect.size.width-self.width)/2 , (allRect.size.height-self.height)/2, self.width, self.height);
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    [self fillRoundedRect:boxRect inContext:ctxt];
}

- (void)fillRoundedRect:(CGRect)rect inContext:(CGContextRef)context {
	
    float radius = 10.0f;
    
    CGContextBeginPath(context);
	CGContextSetGrayFillColor(context, 0.0, self.opacity);
	CGContextMoveToPoint(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect));
    CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMinY(rect) + radius, radius, 3 * M_PI / 2, 0, 0);
    CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMaxY(rect) - radius, radius, 0, M_PI / 2, 0);
    CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMaxY(rect) - radius, radius, M_PI / 2, M_PI, 0);
    CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
	
    CGContextClosePath(context);
    CGContextFillPath(context);
}

#pragma mark cancel event

- (void)cancel:(id)sender
{
	if (delegate != nil)
	{
		if ([delegate respondsToSelector:@selector(hudOperationCancelled:)]) {
			[delegate hudOperationCancelled:self];
		}
	}
}

- (void) enableCancel
{
	if (cancelControl == nil)
	{
		self.detailsLabelText = @"Tap To Cancel";
		cancelControl = [[UIControl alloc] init];
		[cancelControl addTarget:self
						  action:@selector(cancel:)
				forControlEvents:UIControlEventTouchUpInside];
	}
}
	
#pragma mark Tear down

- (void)dealloc {
	[cancelControl release];
	[indicator release];
	[label release];
	[detailsLabel release];
	[labelText release];
	[detailsLabelText release];
    [super dealloc];
}


@end
