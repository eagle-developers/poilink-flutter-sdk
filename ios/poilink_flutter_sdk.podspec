Pod::Spec.new do |s|
  s.name             = 'poilink_flutter_sdk'
  s.version          = '1.0.0'
  s.summary          = 'Poilink SDK for Flutter'
  s.description      = 'Poilink SDK for Flutter - authentication, WebPortal display, mission progress tracking, and item grant sync.'
  s.homepage         = 'https://poilink.com'
  s.license          = { :type => 'Proprietary', :file => '../LICENSE.md' }
  s.author           = { 'Poilink' => 'support@poilink.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '15.0'
  s.dependency 'Flutter'

  s.vendored_frameworks = 'poilink_sdk.xcframework'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'SWIFT_VERSION' => '5.0' }
end
