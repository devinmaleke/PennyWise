//
//  HistoryViewModel.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - FilterPeriod Enum
enum FilterPeriod: String, CaseIterable {
    case today     = "Today"
    case thisWeek  = "This Week"
    case thisMonth = "This Month"
    case allTime   = "All Time"
    
    var dateRange: (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)
            
        case .thisWeek:
            guard let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return nil }
            return (start, now)
            
        case .thisMonth:
            guard let start = calendar.dateInterval(of: .month, for: now)?.start else { return nil }
            return (start, now)
            
        case .allTime:
            return nil // no filter
        }
    }
}

final class HistoryViewModel: ObservableObject {

    @Published var transactions: [TransactionModel] = []
    @Published var categories: [String: CategoryModel] = [:]
    @Published var selectedType: CategoryType = .expense
    @Published var selectedPeriod: FilterPeriod = .thisWeek
    @Published var searchText = ""
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?
    private var categoryListener: ListenerRegistration?

    init() {
        startListening()
        startListeningCategories()
    }

    deinit {
        listener?.remove()
        categoryListener?.remove()
    }

    private func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("transactions")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = AppErrorMapper.message(for: error)
                    }
                    return
                }

                let parsed = snapshot?.documents.compactMap {
                    TransactionModel.from(document: $0)
                } ?? []

                DispatchQueue.main.async {
                    self?.transactions = parsed
                }
            }
    }

    // MARK: - Group by Date

    var groupedTransactions: [(key: String, value: [TransactionModel])] {
        filteredTransactions.groupedByDayDescending()
    }

    // MARK: - Total

    var totalAmount: Int {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    var totalAmountFormatted: String {
        totalAmount.asRupiah
    }

    private func startListeningCategories() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        categoryListener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("categories")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = AppErrorMapper.message(for: error)
                    }
                    return
                }

                var map: [String: CategoryModel] = [:]
                snapshot?.documents.forEach { doc in
                    if let category = CategoryModel.from(document: doc) {
                        map[category.id] = category
                    }
                }

                DispatchQueue.main.async {
                    self?.categories = map
                }
            }
    }

    var showsMonthlyBudget: Bool {
        selectedPeriod == .thisMonth && selectedType == .expense
    }

    var detailStartDate: Date {
        selectedPeriod.dateRange?.start ?? transactions.map(\.date).min() ?? Date()
    }

    var detailEndDate: Date {
        selectedPeriod.dateRange?.end ?? Date()
    }
    
    var groupedByCategory: [(category: CategoryModel, total: Int)] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.category.id }

        return grouped.compactMap { id, list -> (category: CategoryModel, total: Int)? in
            guard let sample = list.first?.category else { return nil }
            let total = list.reduce(0) { $0 + $1.amount }
            return (categories[id] ?? sample, total)
        }
        .sorted { $0.total > $1.total }
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var filteredTransactions: [TransactionModel] {
        transactions.filter { transaction in
            guard transaction.category.type == selectedType else { return false }

            if let range = selectedPeriod.dateRange {
                guard transaction.date >= range.start && transaction.date <= range.end else {
                    return false
                }
            }

            return transaction.matches(searchText)
        }
    }
    
    func transactions(for category: CategoryModel) -> [TransactionModel] {
        transactions.filter { $0.category.id == category.id }
    }
}
