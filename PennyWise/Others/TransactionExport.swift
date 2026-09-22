//
//  TransactionExport.swift
//  PennyWise
//
//  Created by Devin Maleke on 22/09/26.
//

import Foundation

enum ExportPeriod: String, CaseIterable, Identifiable {
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case thisYear = "This Year"
    case allTime = "All Time"

    var id: String { rawValue }

    var fileSlug: String {
        switch self {
        case .thisMonth: return "ThisMonth"
        case .lastMonth: return "LastMonth"
        case .thisYear: return "ThisYear"
        case .allTime: return "AllTime"
        }
    }

    var dateRange: (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        let endOfToday = calendar.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: now
        ) ?? now

        switch self {
        case .thisMonth:
            guard let start = calendar.dateInterval(of: .month, for: now)?.start else {
                return nil
            }
            return (start, endOfToday)

        case .lastMonth:
            guard
                let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start,
                let lastMonthEnd = calendar.date(byAdding: .second, value: -1, to: thisMonthStart),
                let lastMonthStart = calendar.dateInterval(of: .month, for: lastMonthEnd)?.start
            else {
                return nil
            }
            return (lastMonthStart, lastMonthEnd)

        case .thisYear:
            guard let start = calendar.dateInterval(of: .year, for: now)?.start else {
                return nil
            }
            return (start, endOfToday)

        case .allTime:
            return nil
        }
    }
}

enum TransactionCSV {

    static func string(from transactions: [TransactionModel]) -> String {
        let header = [
            "Date",
            "Title",
            "Category",
            "Type",
            "Note",
            "Amount"
        ].joined(separator: ",")

        let rows = transactions
            .sorted { $0.date < $1.date }
            .map { row(from: $0) }

        return ([header] + rows).joined(separator: "\r\n") + "\r\n"
    }

    static func writeTemporaryFile(
        from transactions: [TransactionModel],
        period: ExportPeriod
    ) throws -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let stamp = formatter.string(from: Date())

        let filename = "PennyWise-\(period.fileSlug)-\(stamp).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let bom = "\u{FEFF}"
        let data = Data((bom + string(from: transactions)).utf8)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func row(from transaction: TransactionModel) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let type = transaction.category.type == .income ? "Income" : "Expense"
        return [
            field(formatter.string(from: transaction.date)),
            field(transaction.title),
            field(transaction.category.name),
            field(type),
            field(transaction.note),
            field(String(transaction.amount))
        ].joined(separator: ",")
    }

    private static func field(_ value: String) -> String {
        if value.contains(where: { ",\"\n\r".contains($0) }) {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
