import Foundation
import MMMDCore
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum MMMDPlatformPasteboard {
    static func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

enum MMMDPlatformImage: View {
    case data(Data)

    var body: some View {
        switch self {
        case .data(let data):
            #if canImport(UIKit)
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            #elseif canImport(AppKit)
            if let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            }
            #else
            EmptyView()
            #endif
        }
    }
}

enum MMMDStyleResolver {
    static func color(_ name: String) -> Color {
        if let color = hexColor(name) {
            return color
        }

        switch name {
        case "label":
            return .primary
        case "secondaryLabel":
            return .secondary
        case "systemBlue":
            return .blue
        case "systemPurple":
            return .purple
        case "systemRed":
            return .red
        case "systemOrange":
            return .orange
        case "systemGreen":
            return .green
        case "separator":
            return .primary.opacity(0.16)
        case "secondarySystemBackground":
            return .primary.opacity(0.06)
        case "streamingText":
            return dynamicColor(light: "#322D29", dark: "#D7DEEF")
        case "streamingSecondaryText":
            return dynamicColor(light: "#635C57", dark: "#A4ADC8")
        case "streamingLink":
            return dynamicColor(light: "#7F4400", dark: "#798FD4")
        case "streamingCodeBackground":
            return dynamicColor(light: "#F6E8DD", dark: "#1C2338")
        case "streamingTableBorder":
            return dynamicColor(light: "#EBDBCE", dark: "#2C3860")
        case "streamingCodeBlockBackground":
            return dynamicColor(light: "#322D29", dark: "#1F2431")
        case "streamingCodeBlockHeaderText":
            return dynamicColor(light: "#B3ADA8", dark: "#B3ADA8")
        case "streamingTableHeaderBackground":
            return dynamicColor(light: "#F6E8DD", dark: "#1C2338")
        case "streamingQuoteBorder":
            return dynamicColor(light: "#CFC9C5", dark: "#3E4760")
        case "streamingCodeText":
            return dynamicColor(light: "#F1F1F1", dark: "#E2E2E2")
        case "streamingPageBackground":
            return dynamicColor(light: "#F8F4F1", dark: "#151A28")
        case "demoPresentationText":
            return dynamicColor(light: "#0D213F", dark: "#E0F0FF")
        case "demoPresentationSecondaryText":
            return dynamicColor(light: "#3D567A", dark: "#9EBDE0")
        case "demoPresentationLink":
            return dynamicColor(light: "#0063D1", dark: "#61C2FF")
        case "demoPresentationCodeBackground":
            return dynamicColor(light: "#E0F0FF", dark: "#141F33")
        case "demoPresentationTableBorder", "demoPresentationQuoteBorder":
            return dynamicColor(light: "#94B8E8", dark: "#385680")
        case "demoPresentationCodeBlockBackground":
            return dynamicColor(light: "#0D213F", dark: "#141F33")
        case "demoPresentationCodeBlockHeaderText":
            return dynamicColor(light: "#B9CAE0", dark: "#9EBDE0")
        case "demoPresentationTableHeaderBackground":
            return dynamicColor(light: "#D1E8FF", dark: "#1A2B47")
        case "demoPresentationCodeText":
            return dynamicColor(light: "#C7E6FF", dark: "#C7E6FF")
        case "demoMidnightText":
            return dynamicColor(light: "#1A2947", dark: "#E3EDFA")
        case "demoMidnightSecondaryText":
            return dynamicColor(light: "#4F638A", dark: "#9EAECB")
        case "demoMidnightLink":
            return dynamicColor(light: "#0D75B8", dark: "#66DBFA")
        case "demoMidnightCodeBackground":
            return dynamicColor(light: "#D6E6FC", dark: "#1A1F30")
        case "demoMidnightTableBorder", "demoMidnightQuoteBorder":
            return dynamicColor(light: "#8CA8D6", dark: "#384A6B")
        case "demoMidnightCodeBlockBackground":
            return dynamicColor(light: "#1A2947", dark: "#1A1F30")
        case "demoMidnightCodeBlockHeaderText":
            return dynamicColor(light: "#8CA8D6", dark: "#9EAECB")
        case "demoMidnightTableHeaderBackground":
            return dynamicColor(light: "#C7DBFA", dark: "#1F2940")
        case "demoMidnightCodeText":
            return dynamicColor(light: "#D6E6FC", dark: "#D6E6FC")
        case "demoSepiaText":
            return dynamicColor(light: "#422B14", dark: "#F0D6A8")
        case "demoSepiaSecondaryText":
            return dynamicColor(light: "#78572E", dark: "#BD9963")
        case "demoSepiaLink":
            return dynamicColor(light: "#AD511A", dark: "#F59E4F")
        case "demoSepiaCodeBackground":
            return dynamicColor(light: "#EDD6A8", dark: "#332112")
        case "demoSepiaTableBorder", "demoSepiaQuoteBorder":
            return dynamicColor(light: "#B8915C", dark: "#7A542B")
        case "demoSepiaCodeBlockBackground":
            return dynamicColor(light: "#422B14", dark: "#332112")
        case "demoSepiaCodeBlockHeaderText":
            return dynamicColor(light: "#B8915C", dark: "#BD9963")
        case "demoSepiaTableHeaderBackground":
            return dynamicColor(light: "#E6C793", dark: "#3D2914")
        case "demoSepiaCodeText":
            return dynamicColor(light: "#F4E6CA", dark: "#F4E6CA")
        case "white":
            return .white
        case "black":
            return .black
        default:
            return .primary
        }
    }

    static func font(_ token: FontToken) -> Font {
        .system(size: token.pointSize, weight: weight(token.weight), design: design(token.design))
    }

    static func weight(_ value: String) -> Font.Weight {
        switch value {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }

    private static func design(_ value: String) -> Font.Design {
        switch value {
        case "monospaced": return .monospaced
        case "serif": return .serif
        case "rounded": return .rounded
        default: return .default
        }
    }

    private static func hexColor(_ value: String) -> Color? {
        guard value.hasPrefix("#") else { return nil }
        let hex = String(value.dropFirst())
        guard hex.count == 6 || hex.count == 8, let raw = UInt64(hex, radix: 16) else {
            return nil
        }

        let r: Double
        let g: Double
        let b: Double
        let a: Double
        if hex.count == 8 {
            r = Double((raw & 0xFF00_0000) >> 24) / 255.0
            g = Double((raw & 0x00FF_0000) >> 16) / 255.0
            b = Double((raw & 0x0000_FF00) >> 8) / 255.0
            a = Double(raw & 0x0000_00FF) / 255.0
        } else {
            r = Double((raw & 0xFF0000) >> 16) / 255.0
            g = Double((raw & 0x00FF00) >> 8) / 255.0
            b = Double(raw & 0x0000FF) / 255.0
            a = 1
        }
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    private static func dynamicColor(light: String, dark: String) -> Color {
        #if canImport(UIKit)
        let lightColor = uiColor(light) ?? .label
        let darkColor = uiColor(dark) ?? .label
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? darkColor : lightColor
        })
        #elseif canImport(AppKit)
        let lightColor = nsColor(light) ?? .labelColor
        let darkColor = nsColor(dark) ?? .labelColor
        return Color(NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            return bestMatch == .darkAqua ? darkColor : lightColor
        })
        #else
        return hexColor(light) ?? .primary
        #endif
    }

    #if canImport(UIKit)
    private static func uiColor(_ value: String) -> UIColor? {
        guard let components = hexComponents(value) else { return nil }
        return UIColor(
            red: components.red,
            green: components.green,
            blue: components.blue,
            alpha: components.alpha
        )
    }
    #endif

    #if canImport(AppKit)
    private static func nsColor(_ value: String) -> NSColor? {
        guard let components = hexComponents(value) else { return nil }
        return NSColor(
            calibratedRed: components.red,
            green: components.green,
            blue: components.blue,
            alpha: components.alpha
        )
    }
    #endif

    private static func hexComponents(_ value: String) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        guard value.hasPrefix("#") else { return nil }
        let hex = String(value.dropFirst())
        guard hex.count == 6 || hex.count == 8, let raw = UInt64(hex, radix: 16) else {
            return nil
        }

        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        let a: CGFloat
        if hex.count == 8 {
            r = CGFloat((raw & 0xFF00_0000) >> 24) / 255.0
            g = CGFloat((raw & 0x00FF_0000) >> 16) / 255.0
            b = CGFloat((raw & 0x0000_FF00) >> 8) / 255.0
            a = CGFloat(raw & 0x0000_00FF) / 255.0
        } else {
            r = CGFloat((raw & 0xFF0000) >> 16) / 255.0
            g = CGFloat((raw & 0x00FF00) >> 8) / 255.0
            b = CGFloat(raw & 0x0000FF) / 255.0
            a = 1
        }
        return (r, g, b, a)
    }
}

enum MMMDPlatformTextMeasurer {
    static func width(_ text: String, token: FontToken, weightOverride: String? = nil) -> CGFloat {
        let longestLine = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .max { $0.count < $1.count } ?? text

        #if canImport(UIKit)
        let font = UIFont.systemFont(
            ofSize: CGFloat(token.pointSize),
            weight: uiFontWeight(weightOverride ?? token.weight)
        )
        return (longestLine as NSString).size(withAttributes: [.font: font]).width
        #elseif canImport(AppKit)
        let font = NSFont.systemFont(
            ofSize: CGFloat(token.pointSize),
            weight: nsFontWeight(weightOverride ?? token.weight)
        )
        return (longestLine as NSString).size(withAttributes: [.font: font]).width
        #else
        return CGFloat(longestLine.count) * CGFloat(token.pointSize) * 0.52
        #endif
    }

    #if canImport(UIKit)
    private static func uiFontWeight(_ value: String) -> UIFont.Weight {
        switch value {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
    #elseif canImport(AppKit)
    private static func nsFontWeight(_ value: String) -> NSFont.Weight {
        switch value {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
    #endif
}
