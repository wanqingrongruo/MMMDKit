import Foundation
import MMMDCore
import MMMDMath
import SwiftUI

struct MarkdownCodeBlockView: View {
    let code: CodeBlock
    let context: SwiftUIMarkdownContext
    @State private var highlighted: AttributedString?
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(code.language ?? context.configuration.localization.codeBlockTitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.codeBlockHeaderText))
                Spacer()
                toolbarButton(
                    title: copied ? context.configuration.localization.copied : context.configuration.localization.copy,
                    systemImage: copied ? "checkmark" : "doc.on.doc"
                ) {
                    MMMDPlatformPasteboard.copy(code.content)
                    context.configuration.actions.onCopyCode?(code.content, code.language)
                    copied = true
                    Task {
                        try? await Task.sleep(nanoseconds: 1_400_000_000)
                        copied = false
                    }
                }
                if context.configuration.toolbarOptions.showsDownload {
                    toolbarButton(title: context.configuration.localization.download, systemImage: "arrow.down") {
                        context.configuration.actions.onDownloadCode?(code.content, code.language)
                    }
                }
                if context.configuration.toolbarOptions.showsExpand {
                    toolbarButton(title: context.configuration.localization.expand, systemImage: "arrow.up.left.and.arrow.down.right") {
                        context.configuration.actions.onExpandCode?(code.content, code.language)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(MMMDStyleResolver.color(context.configuration.theme.colors.codeBlockBackground))

            ScrollView(.horizontal) {
                Text(highlighted ?? plainCode)
                    .font(MMMDStyleResolver.font(context.configuration.theme.typography.code))
                    .textSelection(.enabled)
                    .padding(context.configuration.theme.spacing.codePadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(MMMDStyleResolver.color(context.configuration.theme.colors.codeBlockBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .task(id: code.content) {
            await highlight()
        }
    }

    private var plainCode: AttributedString {
        var value = AttributedString(code.content)
        value.font = MMMDStyleResolver.font(context.configuration.theme.typography.code)
        value.foregroundColor = MMMDStyleResolver.color(context.configuration.theme.codeTheme.foregroundColor)
        return value
    }

    private func toolbarButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .regular))
        }
        .buttonStyle(.plain)
        .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.codeBlockHeaderText))
    }

    private func highlight() async {
        guard let highlighter = context.configuration.codeHighlighter else {
            highlighted = nil
            return
        }

        guard let result = try? await highlighter.highlight(
            code: code.content,
            language: code.language,
            theme: context.configuration.theme.codeTheme
        ) else {
            highlighted = nil
            return
        }

        var output = AttributedString()
        for token in result.tokens {
            var segment = AttributedString(token.text)
            segment.font = MMMDStyleResolver.font(context.configuration.theme.typography.code)
            if let scope = token.scope,
               let style = context.configuration.theme.codeTheme.tokenStyles[scope] {
                segment.foregroundColor = MMMDStyleResolver.color(style.foregroundColor)
            } else {
                segment.foregroundColor = MMMDStyleResolver.color(context.configuration.theme.codeTheme.foregroundColor)
            }
            output.append(segment)
        }
        highlighted = output
    }
}

struct MarkdownTableView: View {
    let table: TableBlock
    let context: SwiftUIMarkdownContext
    @State private var copied = false
    @State private var containerWidth: CGFloat = 0

    private enum TableScrollTarget: Hashable {
        case leading
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            scrollableTable

            if context.configuration.toolbarOptions.showsCopy {
                HStack(spacing: 8) {
                    Button {
                        let text = MarkdownTextExtractor.plainText(from: .table(table))
                        MMMDPlatformPasteboard.copy(text)
                        context.configuration.actions.onCopyTable?(text)
                        copied = true
                        Task {
                            try? await Task.sleep(nanoseconds: 1_400_000_000)
                            copied = false
                        }
                    } label: {
                        Label(
                            copied ? context.configuration.localization.copied : context.configuration.localization.copy,
                            systemImage: copied ? "checkmark" : "doc.on.doc"
                        )
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.link))
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
            }
        }
    }

    @ViewBuilder
    private var scrollableTable: some View {
        if usesVirtualizedRows {
            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    HStack(alignment: .top, spacing: 0) {
                        tableLeadingAnchor
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            Section {
                                ForEach(Array(table.rows.enumerated()), id: \.offset) { rowIndex, row in
                                    tableRow(cells: row, isHeader: false, rowIndex: rowIndex + 1)
                                }
                            } header: {
                                tableRow(cells: table.header, isHeader: true, rowIndex: 0)
                            }
                        }
                        .padding(.horizontal, 1)
                        .padding(.bottom, 1)
                        .frame(width: tableWidth, alignment: .leading)
                    }
                }
                .id(tableIdentity)
                .frame(height: maxTableHeight)
                .background(containerWidthReader)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(MMMDStyleResolver.color(context.configuration.theme.colors.tableBorder))
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onAppear {
                    resetScroll(proxy)
                }
                .onChange(of: tableIdentity) { _ in
                    resetScroll(proxy)
                }
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 0) {
                        tableLeadingAnchor
                        VStack(alignment: .leading, spacing: 0) {
                            tableRow(cells: table.header, isHeader: true, rowIndex: 0)
                            ForEach(Array(table.rows.enumerated()), id: \.offset) { rowIndex, row in
                                tableRow(cells: row, isHeader: false, rowIndex: rowIndex + 1)
                            }
                        }
                        .padding(.horizontal, 1)
                        .padding(.bottom, 1)
                        .frame(width: tableWidth, alignment: .leading)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(MMMDStyleResolver.color(context.configuration.theme.colors.tableBorder))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .id(tableIdentity)
                .background(containerWidthReader)
                .onAppear {
                    resetScroll(proxy)
                }
                .onChange(of: tableIdentity) { _ in
                    resetScroll(proxy)
                }
            }
        }
    }

    private var tableLeadingAnchor: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .id(TableScrollTarget.leading)
            .accessibilityHidden(true)
    }

    private var containerWidthReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    containerWidth = proxy.size.width
                }
                .onChange(of: proxy.size.width) { width in
                    containerWidth = width
                }
        }
    }

    private func resetScroll(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo(TableScrollTarget.leading, anchor: .leading)
        }
    }

    private func tableRow(cells: [InlineContent], isHeader: Bool, rowIndex: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<columnCount, id: \.self) { columnIndex in
                let cell = columnIndex < cells.count ? cells[columnIndex] : InlineContent([])
                Text(InlineAttributedStringBuilder.attributedString(from: cell, context: context))
                    .font(isHeader ? .headline : MMMDStyleResolver.font(context.configuration.theme.typography.body))
                    .multilineTextAlignment(textAlignment(forColumn: columnIndex))
                    .frame(maxWidth: .infinity, alignment: alignment(forColumn: columnIndex))
                    .padding(12)
                    .frame(width: width(forColumn: columnIndex), alignment: alignment(forColumn: columnIndex))
                    .accessibilityValue(tableAccessibility(row: rowIndex + 1, column: columnIndex + 1))
            }
        }
        .background(isHeader ? MMMDStyleResolver.color(context.configuration.theme.colors.tableHeaderBackground) : Color.clear)
        .overlay(alignment: .topLeading) {
            tableRowDividers(isLastRow: rowIndex >= table.rows.count)
        }
    }

    private func tableRowDividers(isLastRow: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<max(columnCount - 1, 0), id: \.self) { columnIndex in
                Rectangle()
                    .fill(tableBorderColor)
                    .frame(width: 0.5)
                    .offset(x: tableDividerOffset(afterColumn: columnIndex))
            }

            if !isLastRow {
                VStack {
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(tableBorderColor)
                        .frame(height: 0.5)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var tableBorderColor: Color {
        MMMDStyleResolver.color(context.configuration.theme.colors.tableBorder)
    }

    private func tableDividerOffset(afterColumn columnIndex: Int) -> CGFloat {
        columnWidths.prefix(columnIndex + 1).reduce(0, +)
    }

    private func tableAccessibility(row: Int, column: Int) -> String {
        String(
            format: context.configuration.localization.tableCellPositionFormat,
            row,
            table.rows.count + 1,
            column,
            table.header.count
        )
    }

    private var usesVirtualizedRows: Bool {
        guard let limit = context.configuration.layoutOptions.tableMaximumVisibleRows else {
            return false
        }
        return table.rows.count > limit
    }

    private var maxTableHeight: CGFloat? {
        context.configuration.layoutOptions.tableMaximumHeight.map { CGFloat($0) }
    }

    private var tableCellMinWidth: CGFloat {
        CGFloat(max(44, context.configuration.layoutOptions.tableCellMinWidth))
    }

    private var tableCellMaxWidth: CGFloat {
        let options = context.configuration.layoutOptions
        return CGFloat(max(options.tableCellMinWidth, options.tableCellMaxWidth))
    }

    private var columnCount: Int {
        max(table.header.count, table.rows.map(\.count).max() ?? 0)
    }

    private func width(forColumn columnIndex: Int) -> CGFloat {
        guard columnIndex < columnWidths.count else {
            return tableCellMinWidth
        }
        return columnWidths[columnIndex]
    }

    private var columnWidths: [CGFloat] {
        guard columnCount > 0 else { return [] }

        return (0..<columnCount).map { columnIndex in
            let candidates = [table.header] + table.rows
            let measuredWidth = candidates
                .compactMap { row -> CGFloat? in
                    guard columnIndex < row.count else { return nil }
                    let text = MarkdownTextExtractor.plainText(from: row[columnIndex])
                    return MMMDPlatformTextMeasurer.width(
                        text,
                        token: context.configuration.theme.typography.body
                    )
                }
                .max() ?? 0

            let headerWidth: CGFloat
            if columnIndex < table.header.count {
                headerWidth = MMMDPlatformTextMeasurer.width(
                    MarkdownTextExtractor.plainText(from: table.header[columnIndex]),
                    token: context.configuration.theme.typography.body,
                    weightOverride: "semibold"
                )
            } else {
                headerWidth = 0
            }

            let estimatedWidth = max(measuredWidth, headerWidth) + 32
            return min(max(estimatedWidth, tableCellMinWidth), tableCellMaxWidthForContainer)
        }
    }

    private var tableWidth: CGFloat {
        columnWidths.reduce(0, +) + 2
    }

    private var tableCellMaxWidthForContainer: CGFloat {
        guard columnCount > 0, containerWidth > 0 else {
            return tableCellMaxWidth
        }
        return max(containerWidth / CGFloat(columnCount), tableCellMaxWidth)
    }

    private var tableIdentity: String {
        let previewRows = ([table.header] + Array(table.rows.prefix(12)))
            .map { row in
                row.map(MarkdownTextExtractor.plainText(from:)).joined(separator: "|")
            }
            .joined(separator: "\n")
        return "\(columnCount)x\(table.rows.count):\(previewRows)"
    }

    private func alignment(forColumn columnIndex: Int) -> Alignment {
        switch columnAlignment(forColumn: columnIndex) {
        case .center:
            return .center
        case .trailing:
            return .trailing
        case .leading:
            return .leading
        }
    }

    private func textAlignment(forColumn columnIndex: Int) -> TextAlignment {
        switch columnAlignment(forColumn: columnIndex) {
        case .center:
            return .center
        case .trailing:
            return .trailing
        case .leading:
            return .leading
        }
    }

    private func columnAlignment(forColumn columnIndex: Int) -> MarkdownTableColumnAlignment {
        guard columnIndex < table.columnAlignments.count,
              let alignment = table.columnAlignments[columnIndex] else {
            return .leading
        }
        return alignment
    }
}

struct MarkdownMathBlockView: View {
    let math: MathBlock
    let context: SwiftUIMarkdownContext
    @State private var rendered: MathRenderResult?

    var body: some View {
        Group {
            if let rendered {
                switch rendered.representation {
                case .plainText(let text), .svg(let text):
                    mathText(text)
                case .imageData(let data):
                    MMMDPlatformImage.data(data)
                        .accessibilityLabel(rendered.accessibilityLabel)
                }
            } else {
                mathText(LaTeXPlainTextFormatter.fallbackText(for: math.latex))
            }
        }
        .task(id: math.latex) {
            guard let renderer = context.configuration.mathRenderer else { return }
            rendered = try? await renderer.render(
                latex: math.latex,
                displayMode: math.displayMode,
                environment: .init()
            )
        }
    }

    private func mathText(_ text: String) -> some View {
        ScrollView(.horizontal) {
            Text(text)
                .font(.system(
                    size: max(17, context.configuration.theme.typography.body.pointSize + 2),
                    weight: .regular,
                    design: .serif
                ))
                .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.text))
                .textSelection(.enabled)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(math.latex)
    }
}

struct MarkdownImageBlockView: View {
    let image: ImageBlock
    let context: SwiftUIMarkdownContext
    @State private var data: Data?
    @State private var failed = false
    @State private var isLoading = false
    @State private var failureReason: String?
    @State private var loadedURL: URL?
    @State private var loadAttempt = 0
    @State private var showsPreview = false

    var body: some View {
        Group {
            if let data {
                Button {
                    context.configuration.actions.onImageTap?(image)
                    showsPreview = context.configuration.layoutOptions.showsDefaultImagePreview
                } label: {
                    loadedImage(data)
                }
            } else {
                imagePlaceholder
            }
        }
        .buttonStyle(.plain)
        .background(MMMDStyleResolver.color(context.configuration.theme.colors.codeBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(image.alt.isEmpty ? context.configuration.localization.imagePreview : image.alt)
        .contextMenu {
            if image.url != nil {
                Button {
                    copyImageURL()
                } label: {
                    Label(context.configuration.localization.copy, systemImage: "doc.on.doc")
                }
            }
            if data != nil, context.configuration.layoutOptions.showsDefaultImagePreview {
                Button {
                    showsPreview = true
                } label: {
                    Label(context.configuration.localization.imagePreview, systemImage: "arrow.up.left.and.arrow.down.right")
                }
            }
        }
        .sheet(isPresented: $showsPreview) {
            if let data {
                MarkdownImagePreviewSheet(image: image, data: data, context: context)
            }
        }
        .task(id: imageLoadTaskID) {
            await loadImage()
        }
    }

    private func loadedImage(_ data: Data) -> some View {
        MMMDPlatformImage.data(data)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: imageMaximumHeight)
            .overlay(alignment: .bottomTrailing) {
                if context.configuration.layoutOptions.showsDefaultImagePreview {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .padding(8)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                        .padding(8)
                        .accessibilityHidden(true)
                }
            }
    }

    private var imagePlaceholder: some View {
        VStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            Image(systemName: failed ? "photo.badge.exclamationmark" : "photo")
                .font(.title2)
            Text(placeholderTitle)
                .font(.caption)
            if let failureReason, failed {
                Text(failureReason)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.secondaryText).opacity(0.8))
            }
            if failed, canRetry {
                Button(context.configuration.localization.retry) {
                    failed = false
                    failureReason = nil
                    loadAttempt += 1
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.link))
            }
        }
        .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.secondaryText))
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private var placeholderTitle: String {
        if failed {
            return context.configuration.localization.imageLoadFailed
        }
        return context.configuration.localization.imageLoading
    }

    private var canRetry: Bool {
        image.url != nil && context.configuration.imageLoader != nil
    }

    private var imageMaximumHeight: CGFloat? {
        context.configuration.layoutOptions.imageMaximumHeight.map { CGFloat($0) }
    }

    private var imageLoadTaskID: String {
        "\(image.url?.absoluteString ?? "nil")#\(loadAttempt)"
    }

    private func copyImageURL() {
        guard let url = image.url else { return }
        MMMDPlatformPasteboard.copy(url.absoluteString)
        context.configuration.actions.onCopyImageURL?(image)
    }

    @MainActor
    private func loadImage() async {
        guard loadedURL != image.url || data == nil else {
            return
        }

        data = nil
        loadedURL = nil
        failed = false
        failureReason = nil

        guard let url = image.url, let loader = context.configuration.imageLoader else {
            failed = true
            failureReason = image.url == nil
                ? context.configuration.localization.imageMissingURL
                : context.configuration.localization.imageMissingLoader
            isLoading = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            data = try await loader.loadImageData(from: url)
            loadedURL = url
            failed = false
        } catch {
            failed = true
            failureReason = error.localizedDescription
        }
    }
}

private struct MarkdownImagePreviewSheet: View {
    let image: ImageBlock
    let data: Data
    let context: SwiftUIMarkdownContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(image.alt.isEmpty ? context.configuration.localization.imagePreview : image.alt)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if image.url != nil {
                    Button(context.configuration.localization.copy) {
                        copyImageURL()
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView([.horizontal, .vertical]) {
                MMMDPlatformImage.data(data)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func copyImageURL() {
        guard let url = image.url else { return }
        MMMDPlatformPasteboard.copy(url.absoluteString)
        context.configuration.actions.onCopyImageURL?(image)
    }
}
