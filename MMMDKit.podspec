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
  s.default_subspecs = "Core", "ParserCmark", "Streaming", "Highlighter", "Math", "HTML"

  s.subspec "Core" do |ss|
    ss.source_files = "Sources/MMMDCore/**/*.swift"
  end

  s.subspec "ParserCmark" do |ss|
    ss.dependency "MMMDKit/Core"
    ss.source_files = "Sources/MMMDParserCmark/**/*.swift"
  end

  s.subspec "Streaming" do |ss|
    ss.dependency "MMMDKit/Core"
    ss.source_files = "Sources/MMMDStreaming/**/*.swift"
  end

  s.subspec "Highlighter" do |ss|
    ss.dependency "MMMDKit/Core"
    ss.source_files = "Sources/MMMDHighlighter/**/*.swift"
  end

  s.subspec "Math" do |ss|
    ss.dependency "MMMDKit/Core"
    ss.source_files = "Sources/MMMDMath/**/*.swift"
  end

  s.subspec "HTML" do |ss|
    ss.dependency "MMMDKit/Core"
    ss.source_files = "Sources/MMMDHTML/**/*.swift"
  end

  s.subspec "UIKit" do |ss|
    ss.ios.deployment_target = "15.0"
    ss.dependency "MMMDKit/Core"
    ss.dependency "MMMDKit/Streaming"
    ss.dependency "MMMDKit/Highlighter"
    ss.dependency "MMMDKit/Math"
    ss.dependency "MMMDKit/HTML"
    ss.source_files = "Sources/MMMDUIKit/**/*.swift"
  end

  s.subspec "AppKit" do |ss|
    ss.osx.deployment_target = "12.0"
    ss.dependency "MMMDKit/Core"
    ss.dependency "MMMDKit/Streaming"
    ss.dependency "MMMDKit/Highlighter"
    ss.dependency "MMMDKit/Math"
    ss.dependency "MMMDKit/HTML"
    ss.source_files = "Sources/MMMDAppKit/**/*.swift"
  end
end
