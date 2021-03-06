#import <Foundation/Foundation.h>
#import "LPButton.h"
#import "Utils.h"
#import <QuartzCore/QuartzCore.h>

@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

static NSString * nsDomainString = @"com.tareq.betterccbattery";
static NSString * nsNotificationString = @"com.tareq.betterccbattery/preferences.changed";
static NSString * prefsFile = @"/private/var/mobile/Library/Preferences/com.tareq.betterccbattery.plist";
static BOOL enabled;

%hook CCUIToggleViewController

%property (retain, nonatomic) UILabel* percentLabel;
%property (retain, nonatomic) CALayer* longBatteryBar;
%property (retain, nonatomic) CALayer* shortBatteryBar;
%property (retain, nonatomic) CALayer* wellBatteryBar;
%property (retain, nonatomic) CALayer* batteryLayer;

-(void)viewDidLoad {

	%orig;

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc]
		initWithContentsOfFile: prefsFile];

	enabled = ([prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES);

	if ([self.module isKindOfClass:NSClassFromString(@"CCUILowPowerModule")]) {

		self.batteryLayer = self.view.layer.sublayers[0].sublayers[1].sublayers[0].sublayers[0];

		CATransform3D transform = CATransform3DTranslate(
			CATransform3DMakeScale(1.2, 1.2, 1),
			0, 5, 0
		);

		self.batteryLayer.sublayerTransform = transform;

		for (CALayer* layerItem in self.batteryLayer.sublayers) {

			if ([layerItem.name isEqual: @"yellow long guy that gets short"]) {

				self.longBatteryBar = layerItem;

			} else if ([layerItem.name isEqual: @"white short guy that gets long"]) {

				self.shortBatteryBar = layerItem;

			} else if ([layerItem.name isEqual: @"well"]) {

				self.wellBatteryBar = layerItem;

			}

		}

		self.percentLabel = [[UILabel alloc] init];

		if([self.module isSelected]){
			self.percentLabel.textColor = [UIColor blackColor];
		} else {
			self.percentLabel.textColor = [UIColor whiteColor];
		}

		[self.percentLabel setFont:[UIFont boldSystemFontOfSize:13]];
		[self.view addSubview:self.percentLabel];

	}

}

-(void)touchesEnded:(id)arg1 forEvent:(id)arg2 {
	%orig;
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=BATTERY_USAGE"]];
}

-(void)viewWillAppear:(BOOL)arg1 {
	%orig(arg1);

	int battery = [[UIDevice currentDevice] batteryLevel] * 100;
	self.percentLabel.text = [NSString stringWithFormat:@"%i%%", battery];
	// self.percentLabel.text = [NSString stringWithFormat:@"%@", self.batteryLayer.states];

	[self.percentLabel sizeToFit];
	self.percentLabel.frame = CGRectMake(self.view.frame.size.width/2 - self.percentLabel.frame.size.width/2, self.view.frame.size.height * 0.65, self.percentLabel.frame.size.width, self.percentLabel.frame.size.height);

	[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
	[[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification object:nil queue:
	[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {

		[self refreshIcon];

	}];

	[self refreshIcon];

}

-(void)refreshState {

	%orig;

	[self refreshIcon];

}

%new

-(CGRect)changeWidthOf:(CGRect)rect to:(CGFloat)width {

    return CGRectMake(rect.origin.x, rect.origin.y, width, rect.size.height);

}

%new
-(void)refreshIcon {

	double batteryPercentage =  [self.percentLabel.text doubleValue]/100;
	double maxLength = 26.335199356079;//self.longBatteryBar.bounds.size.width;

	[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];

	// [[UIDevice currentDevice] batteryState] != UIDeviceBatteryStateUnplugged
	// [[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging

	if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging) {

		self.longBatteryBar.backgroundColor  = [[UIColor batteryGreen] CGColor];
		self.shortBatteryBar.backgroundColor = [[UIColor batteryGreen] CGColor];

	} else if ([self.module isSelected]) {

		self.longBatteryBar.backgroundColor  = [[UIColor batteryYellow] CGColor];
		self.shortBatteryBar.backgroundColor = [[UIColor batteryYellow] CGColor];

	} else if (batteryPercentage <= 0.20) {

		self.longBatteryBar.backgroundColor  = [[UIColor batteryRed]    CGColor];
		self.shortBatteryBar.backgroundColor = [[UIColor batteryRed]    CGColor];

	} else {

		self.longBatteryBar.backgroundColor  = [[UIColor whiteColor]    CGColor];
		self.shortBatteryBar.backgroundColor = [[UIColor whiteColor]    CGColor];

	}

	if ([self.module isSelected]) {
		self.percentLabel.textColor = [UIColor batteryYellow];
	} else {
		self.percentLabel.textColor = [UIColor whiteColor];
	}

	/*
		battery glyph has two states: * and enabled
		longBatteryBar  animates 	*: maxLength, 			enabled: batteryPercentage
		shortBatteryBar animates 	*: batteryPercentage, 	enabled: maxLength

		We will add a new state disabled that will overwrite the actions in state *
	*/

	if (self.batteryLayer.states) {

		CAState* enabledState = self.batteryLayer.states[0];

		// if ([self.batteryLayer.states count] <= 1) {

			// CAState* disabledState = [[CAState alloc] init];
			//
			// disabledState.name = @"disabled";
			// disabledState.initial = YES;

			// [disabledState removeElement: [disabledState.elements objectAtIndex:9]];
			// [disabledState removeElement: [disabledState.elements objectAtIndex:8]];
			// [disabledState removeElement: [disabledState.elements objectAtIndex:7]];
			// [disabledState removeElement: [disabledState.elements objectAtIndex:5]];
			// [disabledState removeElement: [disabledState.elements objectAtIndex:4]];
			// [disabledState removeElement: [disabledState.elements objectAtIndex:3]];
			// [disabledState removeElement: [disabledState.elements objectAtIndex:2]];
			// [disabledState removeElement: [disabledState.elements objectAtIndex:1]];
			// [disabledState removeElement: [disabledState.elements objectAtIndex:0]];

			// CAStateSetValue* disabledValueOfStateShortBatteryBar = [disabledState.elements objectAtIndex:0];
			// CAStateSetValue* disabledValueOfStateLongBatteryBar  = [disabledState.elements objectAtIndex:1];
			//
			// [disabledValueOfStateShortBatteryBar setValue: [NSValue valueWithCGRect:
			// 	CGRectMake(0, 0, 26.335235595703, 10.103469848633)
			// ]];
			//
			// [disabledValueOfStateLongBatteryBar setValue: [NSValue valueWithCGRect:
			// 	CGRectMake(0, 0, 4.335235595703, 10.103469848633)
			// ]];

			// NSMutableArray *disabledElements = [NSMutableArray array];
			// [disabledElements addObject: [enabledState.elements objectAtIndex:6]];
			//
			// CAStateSetValue* disabledElementsSetValue = [[CAStateSetValue alloc] init];
			// disabledElementsSetValue.

			// disabledElements[0].bounds = disabledElementsSetValue;
			//
			// disabledState.elements = disabledElements;

			// [self.batteryLayer insertState: disabledState atIndex: 1];

		// }

		CAStateSetValue* valueOfStateShortBatteryBar = [enabledState.elements objectAtIndex:6];
		CAStateSetValue* valueOfStateLongBatteryBar  = [enabledState.elements objectAtIndex:10];

		CGRect rect = CGRectMake(0, 0, maxLength*batteryPercentage, 10.103469848633);//[self changeWidthOf:self.shortBatteryBar.bounds
			// to:maxLength*batteryPercentage];//self.shortBatteryBar.bounds;

		[valueOfStateLongBatteryBar setValue: [NSValue valueWithCGRect:rect]];

		[valueOfStateShortBatteryBar setValue: [NSValue valueWithCGRect:
			CGRectMake(0, 0, maxLength*batteryPercentage, 10.103469848633)
		]];

	}


	//Position overwrites
	self.shortBatteryBar.anchorPoint = CGPointMake(0, 0.5);
	self.longBatteryBar.anchorPoint = CGPointMake(0, 0.5);

	CGPoint pos = self.longBatteryBar.position;
	pos.x = 9.994;

	self.shortBatteryBar.position = pos;
	self.longBatteryBar.position = pos;

	// // Set the width at state * of shortBatteryBar
	self.shortBatteryBar.bounds = CGRectMake(0, 0, maxLength*batteryPercentage, 10.103469848633);
	self.longBatteryBar.bounds = CGRectMake(0, 0, maxLength*batteryPercentage, 10.103469848633);

}

%end

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSNumber * enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:nsDomainString];
	enabled = (enabledValue)? [enabledValue boolValue] : YES;
}

%ctor {
	// Set variables on start up
	notificationCallback(NULL, NULL, NULL, NULL, NULL);

	// Register for 'PostNotification' notifications
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)nsNotificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);

	// Add any personal initializations

}
