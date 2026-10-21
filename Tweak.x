//
//  LilyWhite Tweak.x
//  Status bar capsule background for iOS 16+ / rootless
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class UIStatusBar;

static NSString *const kLWEnabledKey       = @"LWEnabled";
static NSString *const kLWCapsuleColorKey  = @"LWCapsuleColor";
static NSString *const kLWAlphaKey        = @"LWAlpha";
static NSString *const kLWCornerRadiusKey = @"LWCornerRadius";
static NSString *const kLWMarginXKey      = @"LWMarginX";
static NSString *const kLWMarginYKey      = @"LWMarginY";

static NSString *const kLWDefaultsSuite   = @"com.lilywhite.clone";

static UIColor *LWColorFromHex(NSString *hex);
static NSDictionary *LWReadPrefs(void);
static void lwPrefsChangedCallback(CFNotificationCenterRef center,
                                  void *observer,
                                  CFStringRef name,
                                  const void *object,
                                  CFDictionaryRef userInfo);
static void lw_findAndRefreshCapsuleInView(UIView *view);

@interface LWCapsuleBackgroundView : UIView
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat marginX;
@property (nonatomic, assign) CGFloat marginY;
@property (nonatomic, strong) UIColor *capsuleColor;
@property (nonatomic, assign) CGFloat capsuleAlpha;
- (void)refresh;
@end

@interface UIView (LilyWhite)
- (void)lw_attachCapsuleIfNeeded;
- (void)lw_updateCapsuleFrame;
- (void)lw_applyPrefsToCapsule:(LWCapsuleBackgroundView *)bg;
@end

static UIColor *LWColorFromHex(NSString *hex) {
    if (!hex) return [UIColor blackColor];
    NSString *clean = [hex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (clean.length != 6) return [UIColor blackColor];
    NSScanner *scanner = [NSScanner scannerWithString:clean];
    unsigned int rgb;
    if (![scanner scanHexInt:&rgb]) return [UIColor blackColor];
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                           green:((rgb >> 8) & 0xFF) / 255.0
                            blue:(rgb & 0xFF) / 255.0
                           alpha:1.0];
}

static NSDictionary *LWReadPrefs(void) {
    NSDictionary *defaults = @{
        kLWEnabledKey:       @YES,
        kLWCapsuleColorKey:  @"#000000",
        kLWAlphaKey:         @0.35,
        kLWCornerRadiusKey:  @17.0,
        kLWMarginXKey:       @8.0,
        kLWMarginYKey:       @4.0,
    };
    NSDictionary *saved = [[NSDictionary alloc] initWithContentsOfFile:
        [NSString stringWithFormat:@"/var/jb/var/mobile/Library/Preferences/%@.plist", kLWDefaultsSuite]];
    if (saved) {
        NSMutableDictionary *merged = [defaults mutableCopy];
        [merged addEntriesFromDictionary:saved];
        return merged;
    }
    return defaults;
}

@implementation LWCapsuleBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)refresh {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGFloat x = self.marginX;
    CGFloat y = self.marginY;
    CGFloat w = self.bounds.size.width  - self.marginX * 2;
    CGFloat h = self.bounds.size.height - self.marginY * 2;

    CGRect capsuleRect = CGRectMake(x, y, w, h);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:capsuleRect
                                                    cornerRadius:self.cornerRadius];

    CGContextSaveGState(ctx);
    [[self.capsuleColor colorWithAlphaComponent:self.capsuleAlpha] setFill];
    [path fill];
    CGContextRestoreGState(ctx);
}

@end

@implementation UIView (LilyWhite)

- (void)lw_attachCapsuleIfNeeded {
    for (UIView *sub in self.subviews) {
        if ([sub isKindOfClass:[LWCapsuleBackgroundView class]]) {
            return;
        }
    }
    LWCapsuleBackgroundView *bg = [[LWCapsuleBackgroundView alloc] initWithFrame:self.bounds];
    bg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:bg atIndex:0];
    [self lw_applyPrefsToCapsule:bg];
}

- (void)lw_updateCapsuleFrame {
    for (UIView *sub in self.subviews) {
        if ([sub isKindOfClass:[LWCapsuleBackgroundView class]]) {
            LWCapsuleBackgroundView *bg = (LWCapsuleBackgroundView *)sub;
            [self lw_applyPrefsToCapsule:bg];
            [bg refresh];
        }
    }
}

- (void)lw_applyPrefsToCapsule:(LWCapsuleBackgroundView *)bg {
    NSDictionary *prefs = LWReadPrefs();
    BOOL enabled = [prefs[kLWEnabledKey] boolValue];
    bg.hidden = !enabled;
    bg.capsuleColor  = LWColorFromHex(prefs[kLWCapsuleColorKey]);
    bg.capsuleAlpha  = [prefs[kLWAlphaKey] doubleValue];
    bg.cornerRadius  = [prefs[kLWCornerRadiusKey] doubleValue];
    bg.marginX       = [prefs[kLWMarginXKey] doubleValue];
    bg.marginY       = [prefs[kLWMarginYKey] doubleValue];
}

@end

%hook UIStatusBar

- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        UIView *selfView = (UIView *)self;
        [selfView lw_attachCapsuleIfNeeded];
    }
    return self;
}

- (void)layoutSubviews {
    %orig;
    UIView *selfView = (UIView *)self;
    [selfView lw_attachCapsuleIfNeeded];
    [selfView lw_updateCapsuleFrame];
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)app {
    %orig;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge const void *)self,
        (CFNotificationCallback)lwPrefsChangedCallback,
        CFSTR("com.lilywhite.clone.preferences-changed"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);
}

%end

static void lwPrefsChangedCallback(CFNotificationCenterRef center,
                                  void *observer,
                                  CFStringRef name,
                                  const void *object,
                                  CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        for (UIWindow *win in app.windows) {
            lw_findAndRefreshCapsuleInView(win);
        }
    });
}

static void lw_findAndRefreshCapsuleInView(UIView *view) {
    for (UIView *sub in view.subviews) {
        if ([sub isKindOfClass:NSClassFromString(@"UIStatusBar")]) {
            [sub setNeedsLayout];
            [sub layoutIfNeeded];
        } else {
            lw_findAndRefreshCapsuleInView(sub);
        }
    }
}

