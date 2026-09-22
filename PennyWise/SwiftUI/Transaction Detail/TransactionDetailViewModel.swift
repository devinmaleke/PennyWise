//
//  TransactionDetailViewModel.swift
//  PennyWise
//
//  Created by Devin Maleke on 18/03/26.
//

import Foundation

final class TransactionDetailViewModel: ObservableObject {

    let category: CategoryModel
    
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var showDatePicker = false
    @Published var searchText = ""

    @Published private var allTransactions: [TransactionModel]

    init(
        category: CategoryModel,
        transactions: [TransactionModel],
        startDate: Date? = nil,
        endDate: Date? = nil
    ) {
        self.category = category
        self.allTransactions = transactions
        self.startDate = startDate ?? transactions.map(\.date).min() ?? Date()
        self.endDate = endDate ?? Date()
    }

    func apply(_ result: TransactionFormResult) {
        switch result {
        case .saved(let transaction):
            if transaction.category.id != category.id {
                allTransactions.removeAll { $0.id == transaction.id }
            } else if let index = allTransactions.firstIndex(where: { $0.id == transaction.id }) {
                allTransactions[index] = transaction
            } else {
                allTransactions.append(transaction)
            }
        case .deleted(let id):
            allTransactions.removeAll { $0.id == id }
        }
    }

    // MARK: - Filtered by date range

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var dateFilteredTransactions: [TransactionModel] {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate

        return allTransactions.filter { $0.date >= start && $0.date <= end }
    }

    var filteredTransactions: [TransactionModel] {
        dateFilteredTransactions.filter { $0.matches(searchText) }
    }

    // MARK: - Total

    var totalAmount: Int {
        dateFilteredTransactions.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Formatted total

    var formattedTotal: String {
        totalAmount.asRupiah
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

    var thisMonthBudgetStatus: CategoryBudgetStatus? {
        let spent = allTransactions
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
        return CategoryBudgetStatus.from(category: category, spent: spent)
    }

    var groupedByDate: [(key: String, value: [TransactionModel])] {
        filteredTransactions.groupedByDayDescending()
    }
}
