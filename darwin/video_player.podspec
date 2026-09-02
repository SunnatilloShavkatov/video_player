#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint video_player.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'video_player'
  s.version          = '3.4.2'
  s.summary          = 'A Flutter video player plugin with native Android, iOS, and macOS playback.'
  s.description      = <<-DESC
A comprehensive Flutter video player plugin that supports fullscreen and embedded playback
from HTTPS URLs and Flutter assets, with quality selection, speed control, Picture-in-Picture,
and iOS screen protection features across Android, iOS, and macOS.
                       DESC
  s.homepage         = 'https://github.com/SunnatilloShavkatov/video_player'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sunnatillo Shavkatov' => 'sunnatilloshavkatov@gmail.com' }
  s.source           = { :path => '.' }
  s.ios.source_files = 'video_player/Sources/video_player/Common/**/*.{swift,h,m}', 'video_player/Sources/video_player/iOS/**/*.{swift,h,m}', 'video_player/Sources/video_player/VideoPlayerPlugin.swift'
  s.osx.source_files = 'video_player/Sources/video_player/Common/**/*.{swift,h,m}', 'video_player/Sources/video_player/macOS/**/*.{swift,h,m}', 'video_player/Sources/video_player/VideoPlayerPlugin.swift'
  s.resources        = 'video_player/Sources/video_player/Assets/*'
  
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '10.15'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.dependency 'SnapKit', '~> 5.0'

  s.ios.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.osx.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
