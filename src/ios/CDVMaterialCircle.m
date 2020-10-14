/*
 iOS Material Splash preloader
 Initiated show() on plugin initialization
 Follow cordova-plugin-splashscreen configurations from config.xml
 */

#import "CDVMaterialCircle.h"
@import MaterialComponents;

#define kSplashScreenDurationDefault 3000.0f
#define kFadeDurationDefault 500.0f

@implementation CDVMaterialCircle

- (void)pluginInitialize
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageDidLoad) name:CDVPageDidLoadNotification object:nil];

    [self setVisible:YES];
}

- (void)show:(CDVInvokedUrlCommand*)command
{
    [self setVisible:YES];
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    [self setVisible:NO andForce:YES];
}

- (void)pageDidLoad
{
    id autoHideSplashScreenValue = [self.commandDelegate.settings objectForKey:[@"AutoHideSplashScreen" lowercaseString]];

    // if value is missing, default to yes
    if ((autoHideSplashScreenValue == nil) || [autoHideSplashScreenValue boolValue]) {
        [self setVisible:NO];
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    
}

- (void)createViews
{

    UIView* parentView = self.viewController.view;
    parentView.userInteractionEnabled = NO;  // disable user interaction while splashscreen is shown
    
    // Custom activity indicator
    _activityView = [[MDCActivityIndicator alloc] init];
    [_activityView sizeToFit];
    _activityView.center = CGPointMake(parentView.bounds.size.width / 2, parentView.bounds.size.height / 2);
    _activityView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin
    | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
     _activityView.radius = 12;
    _activityView.strokeWidth = 3;
    _activityView.cycleColors = @[UIColor.whiteColor];
    [_activityView startAnimating];
    
    id showSplashScreenSpinnerValue = [self.commandDelegate.settings objectForKey:[@"ShowSplashScreenSpinner" lowercaseString]];
    // backwards compatibility - if key is missing, default to true
    if ((showSplashScreenSpinnerValue == nil) || [showSplashScreenSpinnerValue boolValue])
    {
        [parentView addSubview:_activityView];
    }

    // Frame is required when launching in portrait mode.
    // Bounds for landscape since it captures the rotation.
    [parentView addObserver:self forKeyPath:@"frame" options:0 context:nil];
    [parentView addObserver:self forKeyPath:@"bounds" options:0 context:nil];

    _destroyed = NO;
}

- (void)hideViews
{
    [_activityView setAlpha:0];
}

- (void)destroyViews
{
    _destroyed = YES;

    [_activityView removeFromSuperview];
    _activityView = nil;

    self.viewController.view.userInteractionEnabled = YES;  // re-enable user interaction upon completion
    @try {
        [self.viewController.view removeObserver:self forKeyPath:@"frame"];
        [self.viewController.view removeObserver:self forKeyPath:@"bounds"];
    }
    @catch (NSException *exception) {
        // When reloading the page from a remotely connected Safari, there
        // are no observers, so the removeObserver method throws an exception,
        // that we can safely ignore.
        // Alternatively we can check whether there are observers before calling removeObserver
    }
}



- (void)setVisible:(BOOL)visible
{
    [self setVisible:visible andForce:NO];
}

- (void)setVisible:(BOOL)visible andForce:(BOOL)force
{
    if (visible != _visible || force)
    {
        _visible = visible;

        id fadeSplashScreenValue = [self.commandDelegate.settings objectForKey:[@"FadeSplashScreen" lowercaseString]];
        id fadeSplashScreenDuration = [self.commandDelegate.settings objectForKey:[@"FadeSplashScreenDuration" lowercaseString]];

        float fadeDuration = fadeSplashScreenDuration == nil ? kFadeDurationDefault : [fadeSplashScreenDuration floatValue];

        id splashDurationString = [self.commandDelegate.settings objectForKey: [@"SplashScreenDelay" lowercaseString]];
        float splashDuration = splashDurationString == nil ? kSplashScreenDurationDefault : [splashDurationString floatValue];

        id autoHideSplashScreenValue = [self.commandDelegate.settings objectForKey:[@"AutoHideSplashScreen" lowercaseString]];
        BOOL autoHideSplashScreen = true;

        if (autoHideSplashScreenValue != nil) {
            autoHideSplashScreen = [autoHideSplashScreenValue boolValue];
        }

        if (!autoHideSplashScreen) {
            // CB-10412 SplashScreenDelay does not make sense if the splashscreen is hidden manually
            splashDuration = 0;
        }


        if (fadeSplashScreenValue == nil)
        {
            fadeSplashScreenValue = @"true";
        }

        if (![fadeSplashScreenValue boolValue])
        {
            fadeDuration = 0;
        }
        else if (fadeDuration < 30)
        {
            // [CB-9750] This value used to be in decimal seconds, so we will assume that if someone specifies 10
            // they mean 10 seconds, and not the meaningless 10ms
            fadeDuration *= 1000;
        }

        if (_visible)
        {
            if (_activityView == nil)
            {
                [self createViews];
            }
        }
        else if (fadeDuration == 0 && splashDuration == 0)
        {
            [self destroyViews];
        }
        else
        {
            __weak __typeof(self) weakSelf = self;
            float effectiveSplashDuration;

            // [CB-10562] AutoHideSplashScreen may be "true" but we should still be able to hide the splashscreen manually.
            if (!autoHideSplashScreen || force) {
                effectiveSplashDuration = (fadeDuration) / 1000;
            } else {
                effectiveSplashDuration = (splashDuration - fadeDuration) / 1000;
            }

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (uint64_t) effectiveSplashDuration * NSEC_PER_SEC), dispatch_get_main_queue(), CFBridgingRelease(CFBridgingRetain(^(void) {
                if (!_destroyed) {
                    [UIView transitionWithView:self.viewController.view
                                    duration:(fadeDuration / 1000)
                                    options:UIViewAnimationOptionTransitionNone
                                    animations:^(void) {
                                        [weakSelf hideViews];
                                    }
                                    completion:^(BOOL finished) {
                                        // Always destroy views, otherwise you could have an
                                        // invisible splashscreen that is overlayed over your active views
                                        // which causes that no touch events are passed
                                        if (!_destroyed) {
                                            [weakSelf destroyViews];
                                            // TODO: It might also be nice to have a js event happen here -jm
                                        }
                                    }
                    ];
                }
            })));
        }
    }
}

@end
