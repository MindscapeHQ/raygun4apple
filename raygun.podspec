Pod::Spec.new do |s|
  s.name         = "Raygun"
  s.version      = "1.3.10"
  s.summary      = "Raygun client for Apple platforms"
  s.homepage     = "https://github.com/MindscapeHQ/raygun4apple-samples"
  s.license      = "mit"
  s.authors      = "Raygun"
  s.source       = { :git => "https://github.com/MindscapeHQ/raygun4apple.git",
                     :tag => s.version.to_s }

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = "10.0"
  s.module_name  = "Raygun"
  s.requires_arc = true
  s.frameworks = 'Foundation'
  s.libraries = 'z', 'c++'
  s.xcconfig = { 'GCC_ENABLE_CPP_EXCEPTIONS' => 'YES' }

end