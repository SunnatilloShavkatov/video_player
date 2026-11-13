// Objective-C view of `VideoPlayerApi` (VideoPlayerApi.swift), read by `dart run tool/ffigen.dart` and by the
// generated wrapper video_player_darwin.m. It is private (not in include/), so it never clashes with the Swift
// class. Keep it identical to the Swift @objc API: selectors, parameter types and block signatures are matched at
// runtime.
// A PlayBlock is (positionSeconds, durationSeconds, errorCode, errorMessage): both numbers are -1 and both
// strings nil for a cancelled session, errorCode is non-nil for a failure. Positions are in SECONDS.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayerApi : NSObject

+ (void)playVideo:(NSString *)playerConfigJson callback:(void (^)(NSInteger positionSeconds, NSInteger durationSeconds, NSString *_Nullable errorCode, NSString *_Nullable errorMessage))callback;
+ (void)close:(void (^)(void))callback;

@end

NS_ASSUME_NONNULL_END
