#import "VideoPlayerPlugin.h"
#if __has_include(<video_player/video_player-Swift.h>)
#import <video_player/video_player-Swift.h>
#else
#import "video_player-Swift.h"
#endif

@implementation VideoPlayerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftVideoPlayerPlugin registerWithRegistrar:registrar];
}
@end
