Pod::Spec.new do |s|
  s.name = "MMMDHighlighter"
  s.version = "0.1.0"
  s.summary = "MMMDKit 的代码高亮模块。"
  s.homepage = "https://github.com/wanqingrongruo/MMMDKit"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "wanqingrongruo" => "opensource@example.com" }
  s.source = { :git => "git@github.com:wanqingrongruo/MMMDKit.git", :tag => s.version.to_s }
  s.swift_version = "5.7"
  s.ios.deployment_target = "15.0"
  s.osx.deployment_target = "12.0"
  s.dependency "MMMDCore"
  s.source_files = "Sources/MMMDHighlighter/**/*.swift"
end
