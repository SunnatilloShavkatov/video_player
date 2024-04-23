#import "VideoPlayerPlugin.h"
#import <video_player/video_player-Swift.h>

@implementation VideoPlayerPlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    [SwiftVideoPlayerPlugin registerWithRegistrar:registrar];
}
@end
