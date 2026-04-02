#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint video_player.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'video_player'
  s.version          = '3.0.5'
  s.summary          = 'A Flutter video player plugin with native iOS and Android playback.'
  s.description      = <<-DESC
A comprehensive Flutter video player plugin that supports fullscreen and embedded playback
from HTTPS URLs and Flutter assets, with quality selection, speed control, Picture-in-Picture,
and iOS screen protection features.
                       DESC
  s.homepage         = 'https://github.com/SunnatilloShavkatov/video_player'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sunnatillo Shavkatov' => 'sunnatilloshavkatov@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'SnapKit', '~> 4.0'
  s.resources = 'Assets/*'
  s.static_framework = true

  s.platform = :ios, '15.0'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
