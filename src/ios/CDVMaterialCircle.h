#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
@import MaterialComponents;

@interface CDVMaterialCircle : CDVPlugin {
    MDCActivityIndicator* _activityView;
    BOOL _visible;
    BOOL _destroyed;
}

- (void)show:(CDVInvokedUrlCommand*)command;
- (void)hide:(CDVInvokedUrlCommand*)command;

@end
