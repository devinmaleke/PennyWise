//
//  CurrencyFormatter.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import Foundation

enum CurrencyFormatter {

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.currencySymbol = "Rp "
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static func rupiah(_ value: Int) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "Rp \(value)"
    }
}

enum AmountParser {

    static func parse(_ raw: String) -> Int? {
        let digits = raw.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }

        let capped = digits.count > 12 ? String(digits.prefix(12)) : digits
        return Int(capped)
    }

    static func grouped(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func sanitizedInput(_ raw: String) -> String {
        guard let value = parse(raw) else { return "" }
        return grouped(value)
    }
}

extension Int {
    var asRupiah: String {
        CurrencyFormatter.rupiah(self)
    }

    func signedRupiah(isIncome: Bool) -> String {
        let formatted = asRupiah
        return isIncome ? "+ \(formatted)" : "- \(formatted)"
    }
}
