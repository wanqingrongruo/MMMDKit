import Foundation
import SwiftUI
import MMMDKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@main
struct MMMDKitSwiftUIDemoApp: App {
    @AppStorage(DemoSettings.appearanceModeKey) private var appearanceMode = DemoAppearanceMode.device

    var body: some Scene {
        WindowGroup {
            DemoNavigationView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
    }
}

enum DemoSettings {
    static let preferStreamedMarkdownKey = "preferStreamedMarkdown"
    static let appearanceModeKey = "appearanceMode"
    static let markdownThemeKey = "markdownTheme"
}

enum DemoAppearanceMode: String, CaseIterable, Identifiable {
    case device
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .device: return "Device"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .device: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum Demonstration: String, CaseIterable, Identifiable, Hashable {
    case kitchenSink = "Kitchen Sink"
    case multiParagraph = "Multi-paragraph"
    case images = "Images"
    case tables = "Tables"
    case math = "Math"
    case robotoTheme = "Roboto Themed"
    case `default` = "Default"
    case listPerformance = "List Performance"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .kitchenSink:
            return "A comprehensive markdown content includes dialects and corner cases to showcase everything that's supported and unsupported."
        case .multiParagraph:
            return "Multilingual content with custom interaction callbacks."
        case .images:
            return "Bundle images, inline data images, preview, URL copy and retry states."
        case .tables:
            return "Top 10 populous cities and basic info."
        case .math:
            return "Top 10 most popular math equations."
        case .robotoTheme:
            return "Custom MarkdownTheme: Roboto-inspired sizing with teal-on-purple palette."
        case .default:
            return "Same content as Roboto Themed, rendered with the default MarkdownTheme."
        case .listPerformance:
            return "LazyVStack list rendering with repeated SwiftStreamingMarkdown fixtures."
        }
    }

    var fixtureFileName: String? {
        switch self {
        case .kitchenSink: return "kitchen-sink"
        case .multiParagraph: return "multi-paragraph"
        case .images: return "images"
        case .tables: return "tables"
        case .math: return "math"
        case .robotoTheme, .default: return "roboto"
        case .listPerformance: return nil
        }
    }

    var usesRobotoTheme: Bool {
        self == .robotoTheme
    }
}

enum DemoMarkdownTheme: String, CaseIterable, Identifiable {
    case automatic
    case system
    case roboto
    case presentation
    case midnight
    case sepia

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .system: return "System"
        case .roboto: return "Roboto"
        case .presentation: return "Presentation"
        case .midnight: return "Midnight"
        case .sepia: return "Sepia"
        }
    }

    func resolvedTheme(for demonstration: Demonstration) -> DemoMarkdownTheme {
        switch self {
        case .automatic:
            return demonstration.usesRobotoTheme ? .roboto : .system
        default:
            return self
        }
    }

    func backgroundColor(for demonstration: Demonstration) -> Color {
        switch resolvedTheme(for: demonstration) {
        case .automatic, .system:
            return DemoPalette.systemBackground
        case .roboto:
            return DemoPalette.robotoPageBackground
        case .presentation:
            return DemoPalette.presentation.background
        case .midnight:
            return DemoPalette.midnight.background
        case .sepia:
            return DemoPalette.sepia.background
        }
    }
}

struct DemoNavigationView: View {
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(verbatim: "Loading demonstrations...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(Demonstration.allCases) { demo in
                        NavigationLink(destination: destination(for: demo)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(demo.rawValue)
                                    .font(.headline)
                                Text(demo.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Markdown Demos")
            .toolbar {
                ToolbarItem(placement: settingsToolbarPlacement) {
                    NavigationLink(destination: DemoSettingsView()) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }

            Text("Markdown Demos")
                .foregroundStyle(.secondary)
        }
        .task {
            guard isLoading else { return }
            isLoading = false
        }
    }

    @ViewBuilder
    private func destination(for demonstration: Demonstration) -> some View {
        if demonstration == .listPerformance {
            ListPerformanceScenariosView()
        } else {
            DemonstrationMarkdownView(demonstration: demonstration)
        }
    }

    private var settingsToolbarPlacement: ToolbarItemPlacement {
        #if canImport(UIKit)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }
}

struct DemoSettingsView: View {
    @AppStorage(DemoSettings.preferStreamedMarkdownKey) private var preferStreamedMarkdown = true
    @AppStorage(DemoSettings.appearanceModeKey) private var appearanceMode = DemoAppearanceMode.device
    @AppStorage(DemoSettings.markdownThemeKey) private var markdownTheme = DemoMarkdownTheme.automatic

    var body: some View {
        Form {
            Toggle("Streamed", isOn: $preferStreamedMarkdown)

            Picker("Markdown Theme", selection: $markdownTheme) {
                ForEach(DemoMarkdownTheme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.menu)

            Picker("Appearance", selection: $appearanceMode) {
                ForEach(DemoAppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.menu)
        }
        .navigationTitle("Settings")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct DemonstrationMarkdownView: View {
    @AppStorage(DemoSettings.preferStreamedMarkdownKey) private var preferStreamedMarkdown = true
    @AppStorage(DemoSettings.markdownThemeKey) private var markdownTheme = DemoMarkdownTheme.automatic
    @State private var streamID = UUID()
    @State private var metrics = MarkdownStreamingMetrics()
    @State private var speed = DemoStreamingSpeed.normal
    @State private var isComplete = false
    @State private var showsControls = true
    @State private var followsStreamingOutput = true
    @State private var scrollContainerHeight: CGFloat = 0

    let demonstration: Demonstration
    private static let bottomAnchorID = "stream-bottom-anchor"
    private static let scrollCoordinateSpace = "stream-scroll-space"

    private var markdownText: String {
        DemoFixtureStore.markdown(for: demonstration)
    }

    private var configuration: MarkdownConfiguration {
        DemoMarkdownConfiguration.configuration(for: demonstration, theme: markdownTheme)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Group {
                            if preferStreamedMarkdown {
                                StreamingMarkdownText(
                                    source: DemoStreamingSource.stream(
                                        text: markdownText,
                                        id: streamID,
                                        chunkSize: speed.chunkSize,
                                        interval: speed.interval
                                    ),
                                    inputMode: .delta,
                                    configuration: configuration,
                                    updateInterval: 0.05,
                                    onUpdate: { diff in
                                        metrics = diff.metrics
                                        isComplete = diff.phase == .finished
                                    }
                                )
                                .id("\(demonstration.id)-\(streamID)")
                            } else {
                                MarkdownText(markdownText, configuration: configuration)
                                    .id("\(demonstration.id)-static")
                                    .onAppear {
                                        metrics = MarkdownStreamingMetrics(sourceLength: markdownText.count)
                                        isComplete = true
                                    }
                            }
                        }
                        .padding(.horizontal, 28)
                        .frame(maxWidth: 760, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                        .padding(.bottom, showsControls ? 192 : 64)

                        DemoScrollBottomProbe(
                            anchorID: Self.bottomAnchorID,
                            coordinateSpace: Self.scrollCoordinateSpace
                        )
                    }
                }
                .coordinateSpace(name: Self.scrollCoordinateSpace)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                scrollContainerHeight = proxy.size.height
                            }
                            .onChange(of: proxy.size.height) { height in
                                scrollContainerHeight = height
                            }
                    }
                )
                .background(pageBackground.ignoresSafeArea())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { _ in
                            guard preferStreamedMarkdown else { return }
                            followsStreamingOutput = false
                        }
                )
                .onPreferenceChange(DemoScrollBottomPreferenceKey.self) { bottomY in
                    updateFollowState(bottomY: bottomY)
                }
                .onChange(of: metrics.sourceLength) { _ in
                    guard preferStreamedMarkdown, followsStreamingOutput else { return }
                    scrollToBottom(proxy)
                }
                .onChange(of: streamID) { _ in
                    guard preferStreamedMarkdown else { return }
                    scrollToBottom(proxy, animated: false)
                }
            }

            DemoControlDrawer(
                metrics: metrics,
                totalCharacters: markdownText.count,
                isStreaming: preferStreamedMarkdown,
                isComplete: isComplete,
                speed: $speed,
                isPresented: $showsControls,
                replay: replay,
                fastForward: fastForward
            )
        }
        .onChange(of: demonstration) { _ in
            replay()
        }
        .onChange(of: preferStreamedMarkdown) { _ in
            replay()
        }
        .onChange(of: markdownTheme) { _ in
            replay()
        }
    }

    private var pageBackground: Color {
        markdownTheme.backgroundColor(for: demonstration)
    }

    private func replay() {
        metrics = .init()
        isComplete = false
        followsStreamingOutput = true
        streamID = UUID()
    }

    private func fastForward() {
        speed = .instant
        replay()
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        DispatchQueue.main.async {
            if animated {
                withAnimation(.linear(duration: 0.16)) {
                    proxy.scrollTo(Self.bottomAnchorID, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(Self.bottomAnchorID, anchor: .bottom)
            }
        }
    }

    private func updateFollowState(bottomY: CGFloat) {
        guard preferStreamedMarkdown, scrollContainerHeight > 0, bottomY.isFinite else { return }

        let distanceFromBottom = bottomY - scrollContainerHeight
        if distanceFromBottom <= 36 {
            followsStreamingOutput = true
        }
    }
}

private struct DemoScrollBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct DemoScrollBottomProbe: View {
    let anchorID: String
    let coordinateSpace: String

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: DemoScrollBottomPreferenceKey.self,
                    value: proxy.frame(in: .named(coordinateSpace)).maxY
                )
        }
        .frame(height: 1)
        .id(anchorID)
        .accessibilityHidden(true)
    }
}

struct DemoControlDrawer: View {
    let metrics: MarkdownStreamingMetrics
    let totalCharacters: Int
    let isStreaming: Bool
    let isComplete: Bool
    @Binding var speed: DemoStreamingSpeed
    @Binding var isPresented: Bool
    let replay: () -> Void
    let fastForward: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if isPresented {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            isPresented = false
                        }
                    } label: {
                        Capsule(style: .continuous)
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 42, height: 5)
                            .frame(maxWidth: .infinity)
                            .frame(height: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Hide streaming controls")

                    HStack(spacing: 0) {
                        playbackControls
                        controlDivider
                        speedControls
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: progress)

                        LazyVGrid(columns: metricColumns, alignment: .center, spacing: 8) {
                            metric("Chars", "\(metrics.sourceLength)/\(totalCharacters)")
                            metric("Chunks", "\(metrics.chunkCount)")
                            metric("Renders", "\(metrics.renderCount)")
                            metric("Elapsed", "\(numberText(metrics.elapsed))s")
                            metric("Chars/sec", numberText(charactersPerSecond))
                            metric("Chunks/sec", numberText(chunksPerSecond))
                            metric("Parse", "\(numberText(metrics.parseDuration * 1_000))ms")
                            metric("Render lag", latencyText)
                        }
                    }
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.regularMaterial)
                        .ignoresSafeArea(edges: .bottom)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        isPresented = true
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.headline.weight(.semibold))
                        .frame(width: 96, height: 44)
                        .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .background(.regularMaterial, in: Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.primary.opacity(0.08))
                }
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityLabel("Show streaming controls")
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: isPresented)
        .gesture(
            DragGesture(minimumDistance: 16)
                .onEnded { value in
                    guard abs(value.translation.height) > 28 else { return }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        isPresented = value.translation.height < 0
                    }
                }
        )
    }

    private var playbackControls: some View {
        HStack(spacing: 4) {
            Button(action: replay) {
                controlIcon("arrow.counterclockwise", isSelected: false)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Replay stream")

            Button(action: fastForward) {
                controlIcon("forward.end.fill", isSelected: false)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .disabled(!isStreaming || isComplete)
            .accessibilityLabel("Fast forward stream")
        }
        .frame(maxWidth: .infinity)
    }

    private var speedControls: some View {
        HStack(spacing: 4) {
            speedButton(.slow, systemImage: "tortoise.fill")
            speedButton(.normal, systemImage: "figure.walk")
            speedButton(.fast, systemImage: "hare.fill")
        }
        .frame(maxWidth: .infinity)
    }

    private var controlDivider: some View {
        Divider()
            .frame(width: 1, height: 24)
            .padding(.horizontal, 10)
    }

    private var metricColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    private var progress: Double {
        guard totalCharacters > 0 else { return 0 }
        return min(1, Double(metrics.sourceLength) / Double(totalCharacters))
    }

    private var charactersPerSecond: Double {
        guard metrics.elapsed > 0 else { return 0 }
        return Double(metrics.sourceLength) / metrics.elapsed
    }

    private var chunksPerSecond: Double {
        guard metrics.elapsed > 0 else { return 0 }
        return Double(metrics.chunkCount) / metrics.elapsed
    }

    private var latencyText: String {
        guard let renderLatency = metrics.renderLatency else { return "-" }
        return "\(numberText(renderLatency * 1_000))ms"
    }

    private func speedButton(_ speed: DemoStreamingSpeed, systemImage: String) -> some View {
        Button {
            self.speed = speed
            replay()
        } label: {
            controlIcon(systemImage, isSelected: self.speed == speed)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .disabled(!isStreaming)
        .accessibilityLabel("\(speed.displayName) streaming speed")
    }

    private func controlIcon(_ systemImage: String, isSelected: Bool) -> some View {
        Image(systemName: systemImage)
            .font(.caption.weight(.semibold))
            .frame(width: 44, height: 44)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(Circle().fill(isSelected ? Color.accentColor : Color.primary.opacity(0.08)))
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func numberText(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        }
        if value >= 10 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }
}

enum DemoStreamingSpeed: String, CaseIterable, Identifiable {
    case slow
    case normal
    case fast
    case instant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .slow: return "Slow"
        case .normal: return "Normal"
        case .fast: return "Fast"
        case .instant: return "Instant"
        }
    }

    var interval: UInt64 {
        switch self {
        case .slow: return 220_000_000
        case .normal: return 90_000_000
        case .fast: return 20_000_000
        case .instant: return 0
        }
    }

    var chunkSize: Int {
        switch self {
        case .slow: return 36
        case .normal: return 48
        case .fast: return 96
        case .instant: return 4096
        }
    }
}

enum DemoStreamingSource {
    static func stream(text: String, id: UUID, chunkSize: Int, interval: UInt64) -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                var index = text.startIndex
                while index < text.endIndex {
                    if Task.isCancelled { break }
                    let next = text.index(index, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
                    continuation.yield(String(text[index..<next]))
                    index = next
                    if interval > 0 {
                        try? await Task.sleep(nanoseconds: interval)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

enum ListPerformanceScenario: String, CaseIterable, Identifiable, Hashable {
    case mixedFixtures = "Mixed Fixtures"
    case tableHeavy = "Table Heavy"
    case mathHeavy = "Math Heavy"
    case longKitchenSink = "Long Kitchen Sink"
    case compactMessages = "Compact Messages"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .mixedFixtures:
            return "500 alternating rows from every SwiftStreamingMarkdown fixture."
        case .tableHeavy:
            return "240 table rows to stress horizontal scrolling and cell layout."
        case .mathHeavy:
            return "240 formula rows to stress math parsing and fallback rendering."
        case .longKitchenSink:
            return "120 longer kitchen sink rows with mixed blocks and tables."
        case .compactMessages:
            return "800 shorter rows for high-volume chat style reuse."
        }
    }

    var rowCount: Int {
        switch self {
        case .mixedFixtures: return 500
        case .tableHeavy: return 240
        case .mathHeavy: return 240
        case .longKitchenSink: return 120
        case .compactMessages: return 800
        }
    }

    var fixtureNames: [String] {
        switch self {
        case .mixedFixtures:
            return ["multi-paragraph", "tables", "math", "roboto", "kitchen-sink"]
        case .tableHeavy:
            return ["tables"]
        case .mathHeavy:
            return ["math"]
        case .longKitchenSink:
            return ["kitchen-sink"]
        case .compactMessages:
            return ["multi-paragraph", "roboto"]
        }
    }

    var rowCharacterLimit: Int? {
        switch self {
        case .mixedFixtures:
            return 1_800
        case .longKitchenSink:
            return 4_200
        case .compactMessages:
            return 900
        case .tableHeavy, .mathHeavy:
            return nil
        }
    }

    func messages() -> [DemoListMessage] {
        (0..<rowCount).map { index in
            let fixtureName = fixtureNames[index % fixtureNames.count]
            var markdown = DemoFixtureStore.markdown(named: fixtureName)
                ?? "### Message \(index)\n\nFixture \(fixtureName).md could not be loaded."

            if let rowCharacterLimit, markdown.count > rowCharacterLimit {
                markdown = String(markdown.prefix(rowCharacterLimit))
            }

            return DemoListMessage(
                id: index,
                title: index.isMultiple(of: 2) ? "Assistant" : "User",
                markdown: markdown
            )
        }
    }
}

struct ListPerformanceScenariosView: View {
    var body: some View {
        List(ListPerformanceScenario.allCases) { scenario in
            NavigationLink(destination: ListPerformanceRunView(scenario: scenario)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.rawValue)
                        .font(.headline)
                    Text(scenario.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(scenario.rowCount) rows")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("List Performance")
    }
}

struct ListPerformanceRunView: View {
    @AppStorage(DemoSettings.markdownThemeKey) private var markdownTheme = DemoMarkdownTheme.automatic
    @State private var startedAt: Date?
    @State private var visibleRows: Set<Int> = []
    @State private var firstFullPassDuration: TimeInterval?

    let scenario: ListPerformanceScenario
    private let messages: [DemoListMessage]

    init(scenario: ListPerformanceScenario) {
        self.scenario = scenario
        self.messages = scenario.messages()
    }

    private var configuration: MarkdownConfiguration {
        DemoMarkdownConfiguration.listConfiguration(theme: markdownTheme)
    }

    private var totalCharacters: Int {
        messages.reduce(0) { $0 + $1.markdown.count }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                performanceHeader

                ForEach(messages) { message in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(message.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        MarkdownText(message.markdown, configuration: configuration)
                    }
                    .padding(14)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onAppear {
                        visibleRows.insert(message.id)
                        if message.id == messages.last?.id, firstFullPassDuration == nil, let startedAt {
                            firstFullPassDuration = Date().timeIntervalSince(startedAt)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(DemoPalette.systemBackground.ignoresSafeArea())
        .navigationTitle(scenario.rawValue)
        .onAppear {
            startedAt = startedAt ?? Date()
        }
    }

    private var performanceHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.rawValue)
                    .font(.headline)
                Text(scenario.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 8) {
                metric("Rows", "\(messages.count)")
                metric("Visible", "\(visibleRows.count)")
                metric("Chars", "\(totalCharacters)")
                metric("First pass", firstPassText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var metricColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    private var firstPassText: String {
        guard let firstFullPassDuration else { return "-" }
        return "\(String(format: "%.2f", firstFullPassDuration))s"
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DemoListMessage: Identifiable {
    let id: Int
    let title: String
    let markdown: String
}

enum DemoFixtureStore {
    static func markdown(for demonstration: Demonstration) -> String {
        guard let fixture = demonstration.fixtureFileName else {
            return ""
        }
        return markdown(named: fixture)
            ?? "# Unable to load \(demonstration.rawValue)\n\nExpected fixture: \(fixture).md"
    }

    static func markdown(named name: String) -> String? {
        loadMarkdown(named: name)
    }

    static func listMarkdown(at index: Int) -> String {
        let names = ["multi-paragraph", "tables", "math", "roboto", "kitchen-sink"]
        let name = names[index % names.count]
        let text = markdown(named: name) ?? "### Message \(index)\n\nFixture \(name).md could not be loaded."
        if name == "kitchen-sink" {
            return String(text.prefix(1800))
        }
        return text
    }

    private static func loadMarkdown(named name: String) -> String? {
        let candidates = [
            Bundle.main.url(forResource: name, withExtension: "md", subdirectory: "Fixtures"),
            Bundle.main.url(forResource: name, withExtension: "md", subdirectory: "Resources/Fixtures"),
            Bundle.main.url(forResource: name, withExtension: "md")
        ]

        for url in candidates.compactMap({ $0 }) {
            if let data = try? Data(contentsOf: url),
               let text = String(data: data, encoding: .utf8) {
                return text
            }
        }
        return nil
    }
}

enum DemoMarkdownConfiguration {
    static let defaultConfiguration = MarkdownConfiguration(
        codeHighlighter: CachingCodeHighlighter(base: KeywordCodeHighlighter()),
        mathRenderer: FallbackMathRenderer(),
        imageLoader: CachingImageLoader(base: DemoImageLoader()),
        layoutOptions: streamingLayoutOptions
    )

    static func configuration(for demonstration: Demonstration, theme: DemoMarkdownTheme) -> MarkdownConfiguration {
        configuration(theme: theme.resolvedTheme(for: demonstration), layoutOptions: streamingLayoutOptions)
    }

    static func listConfiguration(theme: DemoMarkdownTheme) -> MarkdownConfiguration {
        configuration(theme: theme.resolvedTheme(for: .listPerformance), layoutOptions: listLayoutOptions)
    }

    private static func configuration(theme: DemoMarkdownTheme, layoutOptions: MarkdownLayoutOptions) -> MarkdownConfiguration {
        var configuration = MarkdownConfiguration(
            codeHighlighter: CachingCodeHighlighter(base: KeywordCodeHighlighter()),
            mathRenderer: FallbackMathRenderer(),
            imageLoader: CachingImageLoader(base: DemoImageLoader()),
            layoutOptions: layoutOptions
        )

        switch theme {
        case .automatic, .system:
            break
        case .roboto:
            configuration.theme = robotoTheme
        case .presentation:
            configuration.theme = paletteTheme(name: "presentation", tokenPrefix: "demoPresentation")
        case .midnight:
            configuration.theme = paletteTheme(name: "midnight", tokenPrefix: "demoMidnight")
        case .sepia:
            configuration.theme = paletteTheme(name: "sepia", tokenPrefix: "demoSepia")
        }
        return configuration
    }

    private static let robotoTheme = MarkdownTheme(
        typography: MarkdownTypography(
            body: .init(textStyle: "body", pointSize: 16, weight: "regular"),
            code: .init(textStyle: "body", pointSize: 15, weight: "regular", design: "monospaced"),
            heading1: .init(textStyle: "largeTitle", pointSize: 32, weight: "medium"),
            heading2: .init(textStyle: "title2", pointSize: 26, weight: "medium")
        ),
        colors: MarkdownColors(
            text: "#EAFBFF",
            secondaryText: "#A7CDD5",
            link: "#55F4D2",
            codeBackground: "#332B58",
            tableBorder: "#6A5FA2",
            codeBlockBackground: "#1D1738",
            codeBlockHeaderText: "#B9B1E6",
            tableHeaderBackground: "#332B58",
            quoteBorder: "#55F4D2"
        ),
        spacing: .streamingDefault,
        codeTheme: CodeTheme(
            name: "roboto-demo",
            foregroundColor: "#F4F7FF",
            backgroundColor: "#1D1738",
            tokenStyles: [
                "keyword": .init(foregroundColor: "#82F7D4", fontTraits: ["bold"]),
                "string": .init(foregroundColor: "#F4D35E"),
                "number": .init(foregroundColor: "#FFB86B"),
                "comment": .init(foregroundColor: "#B9B1E6", fontTraits: ["italic"])
            ]
        )
    )

    private static let streamingLayoutOptions = MarkdownLayoutOptions(
        tableCellMinWidth: 44,
        tableCellMaxWidth: 200
    )

    private static let listLayoutOptions = MarkdownLayoutOptions(
        tableMaximumVisibleRows: 16,
        tableMaximumHeight: 320,
        tableCellMinWidth: 44,
        tableCellMaxWidth: 200
    )

    private static func paletteTheme(name: String, tokenPrefix: String) -> MarkdownTheme {
        MarkdownTheme(
            typography: .streamingDefault,
            colors: MarkdownColors(
                text: "\(tokenPrefix)Text",
                secondaryText: "\(tokenPrefix)SecondaryText",
                link: "\(tokenPrefix)Link",
                codeBackground: "\(tokenPrefix)CodeBackground",
                tableBorder: "\(tokenPrefix)TableBorder",
                codeBlockBackground: "\(tokenPrefix)CodeBlockBackground",
                codeBlockHeaderText: "\(tokenPrefix)CodeBlockHeaderText",
                tableHeaderBackground: "\(tokenPrefix)TableHeaderBackground",
                quoteBorder: "\(tokenPrefix)QuoteBorder"
            ),
            spacing: .streamingDefault,
            codeTheme: CodeTheme(
                name: "demo-\(name)",
                foregroundColor: "\(tokenPrefix)CodeText",
                backgroundColor: "\(tokenPrefix)CodeBlockBackground",
                tokenStyles: [
                    "keyword": .init(foregroundColor: "\(tokenPrefix)Link", fontTraits: ["bold"]),
                    "string": .init(foregroundColor: "\(tokenPrefix)SecondaryText"),
                    "number": .init(foregroundColor: "\(tokenPrefix)Link"),
                    "comment": .init(foregroundColor: "\(tokenPrefix)SecondaryText", fontTraits: ["italic"])
                ]
            )
        )
    }
}

struct DemoImageLoader: ImageLoader {
    func loadImageData(from url: URL) async throws -> Data {
        if isStreamingMarkdownSampleSVG(url) {
            return try DemoGeneratedImage.streamingMarkdownSampleData()
        }

        if url.scheme?.lowercased() == "data" {
            return try dataURLPayload(from: url)
        }

        if url.isFileURL {
            return try Data(contentsOf: url)
        }

        if let localURL = bundleResourceURL(for: url) {
            return try Data(contentsOf: localURL)
        }

        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            throw URLError(.unsupportedURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func dataURLPayload(from url: URL) throws -> Data {
        let value = url.absoluteString
        guard value.hasPrefix("data:"),
              let commaIndex = value.firstIndex(of: ",") else {
            throw URLError(.badURL)
        }

        let metadata = value[value.index(value.startIndex, offsetBy: 5)..<commaIndex]
        let payload = String(value[value.index(after: commaIndex)...])
        if metadata.lowercased().split(separator: ";").contains("base64") {
            let base64 = payload.removingPercentEncoding ?? payload
            guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {
                throw URLError(.cannotDecodeContentData)
            }
            return data
        }

        guard let decoded = payload.removingPercentEncoding,
              let data = decoded.data(using: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return data
    }

    private func isStreamingMarkdownSampleSVG(_ url: URL) -> Bool {
        resourcePathCandidates(for: url).contains { path in
            let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
            return normalized == "streaming-markdown.svg"
                || normalized == "images/streaming-markdown.svg"
        }
    }

    private func bundleResourceURL(for url: URL) -> URL? {
        for path in resourcePathCandidates(for: url) {
            let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !normalized.isEmpty else { continue }

            let nsPath = normalized as NSString
            let fileName = nsPath.lastPathComponent as NSString
            let resourceName = fileName.deletingPathExtension
            let fileExtension = fileName.pathExtension
            let subdirectory = nsPath.deletingLastPathComponent
            let directories = subdirectory.isEmpty ? [""] : [subdirectory, ""]

            for directory in directories {
                if let url = Bundle.main.url(
                    forResource: resourceName,
                    withExtension: fileExtension.isEmpty ? nil : fileExtension,
                    subdirectory: directory.isEmpty ? nil : directory
                ) {
                    return url
                }
            }
        }
        return nil
    }

    private func resourcePathCandidates(for url: URL) -> [String] {
        [
            url.relativePath,
            url.path,
            url.relativeString,
            url.absoluteString
        ]
        .compactMap { value in
            value.removingPercentEncoding
        }
        .filter { !$0.isEmpty && !$0.contains("://") }
    }
}

private enum DemoGeneratedImage {
    static func streamingMarkdownSampleData() throws -> Data {
        let size = CGSize(width: 640, height: 320)
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.pngData { _ in
            drawUIKitSample(size: size)
        }
        #elseif canImport(AppKit)
        let image = NSImage(size: size)
        image.lockFocus()
        drawAppKitSample(size: size)
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let representation = NSBitmapImageRep(data: tiff),
              let png = representation.representation(using: .png, properties: [:]) else {
            throw URLError(.cannotDecodeContentData)
        }
        return png
        #else
        throw URLError(.unsupportedURL)
        #endif
    }

    #if canImport(UIKit)
    private static func drawUIKitSample(size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let card = UIBezierPath(roundedRect: rect, cornerRadius: 32)
        card.addClip()

        let context = UIGraphicsGetCurrentContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                (UIColor(hex: "#2B1B5A") ?? .systemPurple).cgColor,
                (UIColor(hex: "#123F5A") ?? .systemTeal).cgColor
            ] as CFArray,
            locations: [0, 1]
        ) {
            context?.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }

        (UIColor(hex: "#72F2D8") ?? .systemTeal).withAlphaComponent(0.85).setFill()
        UIBezierPath(ovalIn: CGRect(x: 68, y: 60, width: 56, height: 56)).fill()
        (UIColor(hex: "#8FB8FF") ?? .systemBlue).withAlphaComponent(0.18).setFill()
        UIBezierPath(ovalIn: CGRect(x: 500, y: 188, width: 88, height: 88)).fill()

        strokeUIKitLine(y: 104, fromX: 132, toX: 508, color: .white.withAlphaComponent(0.18), width: 14)
        strokeUIKitLine(y: 160, fromX: 96, toX: 544, color: UIColor(hex: "#72F2D8") ?? .systemTeal, width: 18)
        strokeUIKitLine(y: 216, fromX: 96, toX: 400, color: .white.withAlphaComponent(0.65), width: 14)

        ("# Markdown" as NSString).draw(
            at: CGPoint(x: 96, y: 136),
            withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 44, weight: .bold),
                .foregroundColor: UIColor(hex: "#10223A") ?? .black
            ]
        )
        ("**streaming** `tokens`" as NSString).draw(
            at: CGPoint(x: 96, y: 226),
            withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 24, weight: .regular),
                .foregroundColor: UIColor.white
            ]
        )
    }

    private static func strokeUIKitLine(y: CGFloat, fromX: CGFloat, toX: CGFloat, color: UIColor, width: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: fromX, y: y))
        path.addLine(to: CGPoint(x: toX, y: y))
        path.lineWidth = width
        path.lineCapStyle = .round
        color.setStroke()
        path.stroke()
    }
    #elseif canImport(AppKit)
    private static func drawAppKitSample(size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let card = NSBezierPath(roundedRect: rect, xRadius: 32, yRadius: 32)

        NSGraphicsContext.saveGraphicsState()
        card.addClip()
        NSGradient(
            starting: NSColor(hex: "#2B1B5A") ?? .systemPurple,
            ending: NSColor(hex: "#123F5A") ?? .systemTeal
        )?.draw(in: card, angle: -35)

        (NSColor(hex: "#72F2D8") ?? .systemTeal).withAlphaComponent(0.85).setFill()
        NSBezierPath(ovalIn: flippedRect(x: 68, y: 60, width: 56, height: 56, canvasHeight: size.height)).fill()
        (NSColor(hex: "#8FB8FF") ?? .systemBlue).withAlphaComponent(0.18).setFill()
        NSBezierPath(ovalIn: flippedRect(x: 500, y: 188, width: 88, height: 88, canvasHeight: size.height)).fill()

        strokeAppKitLine(y: 104, fromX: 132, toX: 508, color: .white.withAlphaComponent(0.18), width: 14, canvasHeight: size.height)
        strokeAppKitLine(y: 160, fromX: 96, toX: 544, color: NSColor(hex: "#72F2D8") ?? .systemTeal, width: 18, canvasHeight: size.height)
        strokeAppKitLine(y: 216, fromX: 96, toX: 400, color: .white.withAlphaComponent(0.65), width: 14, canvasHeight: size.height)

        ("# Markdown" as NSString).draw(
            at: NSPoint(x: 96, y: size.height - 182),
            withAttributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 44, weight: .bold),
                .foregroundColor: NSColor(hex: "#10223A") ?? .black
            ]
        )
        ("**streaming** `tokens`" as NSString).draw(
            at: NSPoint(x: 96, y: size.height - 256),
            withAttributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 24, weight: .regular),
                .foregroundColor: NSColor.white
            ]
        )
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func strokeAppKitLine(
        y: CGFloat,
        fromX: CGFloat,
        toX: CGFloat,
        color: NSColor,
        width: CGFloat,
        canvasHeight: CGFloat
    ) {
        let path = NSBezierPath()
        let flippedY = canvasHeight - y
        path.move(to: NSPoint(x: fromX, y: flippedY))
        path.line(to: NSPoint(x: toX, y: flippedY))
        path.lineWidth = width
        path.lineCapStyle = .round
        color.setStroke()
        path.stroke()
    }

    private static func flippedRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, canvasHeight: CGFloat) -> CGRect {
        CGRect(x: x, y: canvasHeight - y - height, width: width, height: height)
    }
    #endif
}

enum DemoPalette {
    struct PaletteColors {
        let background: Color
    }

    static var systemBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        #endif
    }

    static var sidebarBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .underPageBackgroundColor)
        #else
        return Color.primary.opacity(0.04)
        #endif
    }

    static var robotoPageBackground: Color {
        dynamicColor(light: "#27184C", dark: "#120B24")
    }

    static var presentation: PaletteColors {
        PaletteColors(background: dynamicColor(light: "#F2FAFF", dark: "#081221"))
    }

    static var midnight: PaletteColors {
        PaletteColors(background: dynamicColor(light: "#EBF2FF", dark: "#0A0D17"))
    }

    static var sepia: PaletteColors {
        PaletteColors(background: dynamicColor(light: "#FAEDD6", dark: "#21170D"))
    }

    private static func dynamicColor(light: String, dark: String) -> Color {
        #if canImport(UIKit)
        let lightColor = UIColor(hex: light) ?? .systemBackground
        let darkColor = UIColor(hex: dark) ?? .systemBackground
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? darkColor : lightColor
        })
        #elseif canImport(AppKit)
        let lightColor = NSColor(hex: light) ?? .windowBackgroundColor
        let darkColor = NSColor(hex: dark) ?? .windowBackgroundColor
        return Color(NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            return bestMatch == .darkAqua ? darkColor : lightColor
        })
        #else
        return Color(.sRGB, red: 0.15, green: 0.10, blue: 0.30, opacity: 1)
        #endif
    }
}

#if canImport(UIKit)
private extension UIColor {
    convenience init?(hex: String) {
        guard let components = DemoHexColor.components(hex) else { return nil }
        self.init(red: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
    }
}
#elseif canImport(AppKit)
private extension NSColor {
    convenience init?(hex: String) {
        guard let components = DemoHexColor.components(hex) else { return nil }
        self.init(calibratedRed: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
    }
}
#endif

enum DemoHexColor {
    static func components(_ value: String) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        guard value.hasPrefix("#") else { return nil }
        let hex = String(value.dropFirst())
        guard hex.count == 6 || hex.count == 8, let raw = UInt64(hex, radix: 16) else {
            return nil
        }

        if hex.count == 8 {
            return (
                CGFloat((raw & 0xFF00_0000) >> 24) / 255.0,
                CGFloat((raw & 0x00FF_0000) >> 16) / 255.0,
                CGFloat((raw & 0x0000_FF00) >> 8) / 255.0,
                CGFloat(raw & 0x0000_00FF) / 255.0
            )
        }

        return (
            CGFloat((raw & 0xFF0000) >> 16) / 255.0,
            CGFloat((raw & 0x00FF00) >> 8) / 255.0,
            CGFloat(raw & 0x0000FF) / 255.0,
            1
        )
    }
}
