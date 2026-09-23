//
//  AppearanceStore.swift
//  PennyWise
//
//  Created by Devin Maleke on 22/09/26.
//

import Combine
import SwiftUI
import UIKit

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

final class AppearanceStore: ObservableObject {

    static let shared = AppearanceStore()

    private let key = "appearance.mode"

    @Published var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: key)
            apply()
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: key),
           let stored = AppearanceMode(rawValue: raw) {
            mode = stored
        } else {
            mode = .system
        }
    }

    func apply(to window: UIWindow? = nil) {
        let style = mode.interfaceStyle
        let windows: [UIWindow]
        if let window = window {
            windows = [window]
        } else {
            windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .filter { $0.windowLevel == .normal }
        }
        windows.forEach { $0.overrideUserInterfaceStyle = style }
        applyChrome()
    }

    private func applyChrome() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = .pwBackground
        nav.titleTextAttributes = [.foregroundColor: UIColor.pwInk]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.pwInk]
        nav.shadowColor = .clear

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = nav
        navBar.scrollEdgeAppearance = nav
        navBar.compactAppearance = nav
        navBar.tintColor = .pwInk

        UITableView.appearance().backgroundColor = .pwBackground
        UITableView.appearance().separatorColor = .pwDivider
        UITextField.appearance().keyboardAppearance = .default
    }
}

extension UIColor {

    static let pwBackground = dynamic(light: "FAFAFA", dark: "12181F")
    static let pwCard = UIColor { trait in
        Palette.isDark(trait) ? UIColor(hex: "1B2530") : .white
    }
    static let pwInk = dynamic(light: "1D2E3E", dark: "F2F5F7")
    static let pwMuted = dynamic(light: "466C85", dark: "9BB0BF")
    static let pwFill = dynamic(light: "EFF3F6", dark: "243140")
    static let pwDivider = dynamic(light: "F1ECEC", dark: "2A3846")
    static let pwAccent = dynamic(light: "1D2E3E", dark: "3D566C")
    static let pwChip = dynamic(light: "F9F9FC", dark: "243140")
    static let pwOnAccent = UIColor(hex: "F9F9FC")

    private static func dynamic(light: String, dark: String) -> UIColor {
        UIColor { trait in
            UIColor(hex: Palette.isDark(trait) ? dark : light)
        }
    }
}

enum Palette {

    static func isDark(_ trait: UITraitCollection = .current) -> Bool {
        switch AppearanceStore.shared.mode {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            let style = trait.userInterfaceStyle == .unspecified
                ? UITraitCollection.current.userInterfaceStyle
                : trait.userInterfaceStyle
            return style == .dark
        }
    }

    static func isDark(scheme: ColorScheme) -> Bool {
        switch AppearanceStore.shared.mode {
        case .dark: return true
        case .light: return false
        case .system: return scheme == .dark
        }
    }
}

extension Color {
    static var appBackground: Color { Color(UIColor.pwBackground) }
    static var appCard: Color { Color(UIColor.pwCard) }
    static var appInk: Color { Color(UIColor.pwInk) }
    static var appMuted: Color { Color(UIColor.pwMuted) }
    static var appFill: Color { Color(UIColor.pwFill) }
    static var appDivider: Color { Color(UIColor.pwDivider) }
    static var appAccent: Color { Color(UIColor.pwAccent) }
    static var appChip: Color { Color(UIColor.pwChip) }
    static let appOnAccent = Color(hex: "F9F9FC")

    static func card(for scheme: ColorScheme) -> Color {
        Palette.isDark(scheme: scheme) ? Color(hex: "1B2530") : .white
    }

    static func chip(for scheme: ColorScheme) -> Color {
        Color(hex: Palette.isDark(scheme: scheme) ? "243140" : "F9F9FC")
    }
}
