Pod::Spec.new do |s|
  s.name = "MMMDAppKit"
  s.version = "0.1.0"
  s.summary = "MMMDKit 的 AppKit 渲染模块。"
  s.homepage = "https://github.com/wanqingrongruo/MMMDKit"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "wanqingrongruo" => "opensource@example.com" }
  s.source = { :git => "git@github.com:wanqingrongruo/MMMDKit.git", :tag => s.version.to_s }
  s.swift_version = "5.7"
  s.osx.deployment_target = "12.0"
  s.dependency "MMMDCore"
  s.dependency "MMMDHighlighter"
  s.dependency "MMMDMath"
  s.dependency "MMMDHTML"
  s.dependency "MMMDStreaming"
  s.frameworks = "AppKit", "WebKit"
  s.source_files = "Sources/MMMDAppKit/**/*.swift"
end
