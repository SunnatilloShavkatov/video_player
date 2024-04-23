#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint udevs_video_player.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'udevs_video_player'
  s.version          = '1.0.0'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'udevs4help@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'TinyConstraints'
  s.dependency 'NVActivityIndicatorView'
  s.dependency 'XLActionController'
  s.dependency 'ScreenshotPreventing', '~> 1.4.0'
  s.dependency 'SnapKit', '~> 4.0'
  s.dependency 'SDWebImage', '~> 5.0'
  s.resources = 'Assets/*'
  s.static_framework = true

  s.platform = :ios, '12.0'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
