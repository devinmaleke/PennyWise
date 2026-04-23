//
//  TransactionDetailViewModel.swift
//  PennyWise
//
//  Created by Samir iOS on 18/03/26.
//

import Foundation

final class TransactionDetailViewModel: ObservableObject {

    let category: CategoryModel
    
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var showDatePicker = false

    private let allTransactions: [TransactionModel]

    init(category: CategoryModel, transactions: [TransactionModel]) {
        self.category = category
        self.allTransactions = transactions
        self.startDate = transactions.map(\.date).min() ?? Date()
        self.endDate = Date()
    }

    // MARK: - Filtered by date range

    var filteredTransactions: [TransactionModel] {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate

        return allTransactions.filter { $0.date >= start && $0.date <= end }
    }

    // MARK: - Total

    var totalAmount: Int {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Formatted total

    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.currencySymbol = "Rp "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "Rp 0"
    }

    // MARK: - Date label

    var dateRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        let s = formatter.string(from: startDate)
        let e = formatter.string(from: endDate)
        return s == e ? s : "\(s) – \(e)"
    }

    // MARK: - Grouped by date (untuk section header)

    var groupedByDate: [(key: String, value: [TransactionModel])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"

        let grouped = Dictionary(grouping: filteredTransactions) {
            formatter.string(from: $0.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
}
