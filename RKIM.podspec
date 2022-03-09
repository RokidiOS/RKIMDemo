#
# Be sure to run `pod lib lint RKIM.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RKIM'
  s.version          = '0.1.0'
  s.summary          = 'A short description of RKIM.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/chzy/RKIM'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'chzy' => 'yang.chunzhi@hotmail.com' }
  s.source           = { :git => 'git@gitlab.rokid-inc.com:xr_app_platform/ios/component/rkim.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'
  s.source_files = [
  'RKIM/Classes/**/*'
  ]
  
  s.dependency 'Moya', '~> 13.0.1'
  s.dependency 'RKHandyJSON'
  s.dependency 'Kingfisher', '~>4.10.1'
  s.dependency 'SnapKit', '~> 4.2.0'
  s.dependency 'Then', '~> 2.7.0'
  s.dependency 'IQKeyboardManager', '~> 6.5.6'
  s.dependency 'RKLogger'
  s.dependency 'RKSocket'
  s.dependency 'RKBaseView'
  s.dependency 'LookinServer', :configurations => ['Debug']
#  s.dependency 'RKImagePicker', '~> 0.1.1'
  s.dependency 'JXPhotoBrowser'#, '~> 3.1.4'
  s.dependency 'WCDB.swift'
  s.dependency 'TZImagePickerController'
  s.dependency 'RKIMCore'
  
   s.resource_bundles = {
     'RK' => ['RKIM/Assets/**/*']
   }
   #走 framework
#   s.ios.vendored_frameworks = "RKIM/frameworks/*.framework"
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

