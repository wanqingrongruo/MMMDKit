Pod::Spec.new do |s|
  s.name = "MMMDKit"
  s.version = "0.1.0"
  s.summary = "面向 Apple 平台的模块化原生 Markdown 渲染框架。"
  s.description = <<-DESC
    MMMDKit 是面向 iOS、iPadOS 和 macOS 的模块化原生 Markdown 渲染框架。
    它为 AI 流式输出、原生滚动性能、复制、选择、无障碍、动态字体、
    代码高亮、表格、LaTeX 和 HTML fallback 场景设计。
  DESC
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
  s.source_files = "Sources/MMMDKit/**/*.swift"
end
