# For a build that installs plugins with CocoaPods; Swift Package Manager
# reads niman_apple/Package.swift.
Pod::Spec.new do |s|
  s.name             = 'niman_apple'
  s.version          = '0.0.1'
  s.summary          = "Niman's native code for macOS and iOS."
  s.homepage         = 'https://github.com/Nihmar/Niman'
  s.license          = { :type => 'MIT', :file => '../../../LICENSE' }
  s.author           = 'Niman'
  s.source           = { :path => '.' }
  s.source_files     = 'niman_apple/Sources/niman_apple/**/*.swift'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '17.0'
  s.osx.deployment_target = '14.0'
  s.swift_version = '5.0'
end
