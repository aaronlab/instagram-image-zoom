platform :ios, '15.0'
inhibit_all_warnings!

target 'InstagramStyleImageZoomExample' do

  use_frameworks!

  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxGesture'
  pod 'RxDataSources'

  pod 'SnapKit'
  pod 'Then'
  pod 'Kingfisher'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end