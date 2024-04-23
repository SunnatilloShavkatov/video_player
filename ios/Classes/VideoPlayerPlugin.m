#import VideoPlayerPlugin.h
#import <udevs_video_player/udevs_video_player-Swift.h>

@implementation VideoPlayerPlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    [SwiftUdevsVideoPlayerPlugin registerWithRegistrar:registrar];
}
@end
