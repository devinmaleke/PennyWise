//
//  Extensions.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import UIKit
import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appDivider, lineWidth: 1)
            )
    }
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}

extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: self)
    }
    
    static var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
}

extension UIColor {

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }
}

extension UIViewController {

    private static let loadingOverlayTag = 9_810_214

    func showAlert(_ message: String, title: String = "Error") {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func setLoading(_ isLoading: Bool) {
        view.isUserInteractionEnabled = !isLoading

        if isLoading {
            guard view.viewWithTag(Self.loadingOverlayTag) == nil else { return }

            let overlay = UIView(frame: view.bounds)
            overlay.tag = Self.loadingOverlayTag
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.25)
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            let spinner = UIActivityIndicatorView(style: .large)
            spinner.color = .white
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            overlay.addSubview(spinner)

            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
            ])

            view.addSubview(overlay)
        } else {
            view.viewWithTag(Self.loadingOverlayTag)?.removeFromSuperview()
        }
    }
}
