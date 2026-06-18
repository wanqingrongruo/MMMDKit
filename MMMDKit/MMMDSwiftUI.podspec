Pod::Spec.new do |s|
  s.name = "MMMDSwiftUI"
  s.version = "0.2.0-alpha"
  s.summary = "MMMDKit 的 SwiftUI-only Markdown 渲染模块。"
  s.homepage = "https://github.com/wanqingrongruo/MMMDKit"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "wanqingrongruo" => "opensource@example.com" }
  s.source = { :git => "git@github.com:wanqingrongruo/MMMDKit.git", :tag => s.version.to_s }
  s.swift_version = "5.7"
  s.ios.deployment_target = "15.0"
  s.osx.deployment_target = "12.0"
  s.dependency "MMMDCore"
  s.dependency "MMMDParserCmark"
  s.dependency "MMMDStreaming"
  s.dependency "MMMDHighlighter"
  s.dependency "MMMDMath"
  s.dependency "MMMDHTML"
  s.frameworks = "SwiftUI"
  s.source_files = "Sources/MMMDSwiftUI/**/*.swift"
end
