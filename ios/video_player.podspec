#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint video_player.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'video_player'
  s.version          = '2.0.0'
  s.summary          = 'A Flutter video player plugin with download support and advanced features.'
  s.description      = <<-DESC
A comprehensive Flutter video player plugin that supports playing videos from URLs and assets,
downloading videos for offline playback, quality selection, and screen protection features.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'sunnatilloshavkatov@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'TinyConstraints'
  s.dependency 'NVActivityIndicatorView'
  s.dependency 'XLActionController'
  s.dependency 'SnapKit', '~> 4.0'
  s.dependency 'SDWebImage', '~> 5.0'
  s.resources = 'Assets/*'
  s.static_framework = true

  s.platform = :ios, '15.0'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
