// Keeps the video_player_c target a valid Clang module; the Objective-C view of the Swift API lives next to it
// in video_player_api.h, outside include/, so it never clashes with the Swift classes.
#import <Foundation/Foundation.h>
