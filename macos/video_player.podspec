#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint video_player.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'video_player'
  s.version          = '3.4.1'
  s.summary          = 'A Flutter video player plugin with native macOS, iOS, and Android playback.'
  s.description      = <<-DESC
A comprehensive Flutter video player plugin that supports fullscreen and embedded playback
from HTTPS URLs and Flutter assets across Android, iOS, and macOS.
                       DESC
  s.homepage         = 'https://github.com/SunnatilloShavkatov/video_player'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sunnatillo Shavkatov' => 'sunnatilloshavkatov@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'video_player/Sources/video_player/**/*.{swift,h,m}'
  s.resources        = 'video_player/Sources/video_player/Assets/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
