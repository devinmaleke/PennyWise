//
//  HomeViewModel.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case income = "Income"
    case expense = "Expense"
}

struct SpendComparison {
    let text: String
    let systemImage: String
}

final class HomeViewModel: ObservableObject {

    @Published var userName: String = ""
    @Published var categories: [String: CategoryModel] = [:]
    @Published var transactions: [TransactionModel] = []
    @Published var selectedFilter: TransactionFilter = .all
    @Published var selectedMonth: Date = HomeViewModel.startOfMonth(Date())
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var transactionListener: ListenerRegistration?
    private var categoryListener: ListenerRegistration?
    private var didAttemptDefaultSeed = false

    init() {
        fetchUser()
        fetchCategoriesAndTransactions()
    }

    deinit {
        transactionListener?.remove()
        categoryListener?.remove()
    }

    // MARK: - Computed

    var filteredTransactions: [TransactionModel] {
        switch selectedFilter {
        case .all:
            return monthTransactions
        case .income:
            return monthTransactions.filter { $0.category.type == .income }
        case .expense:
            return monthTransactions.filter { $0.category.type == .expense }
        }
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: selectedMonth)
    }

    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    var canGoToPreviousMonth: Bool {
        guard let previous = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) else {
            return false
        }
        return Calendar.current.compare(previous, to: earliestMonth, toGranularity: .month) != .orderedAscending
    }

    var canGoToNextMonth: Bool {
        !isCurrentMonth
    }

    var monthBalanceFormatted: String {
        monthBalance.asRupiah
    }

    var monthIncomeFormatted: String {
        monthIncome.asRupiah
    }

    var monthSpendFormatted: String {
        monthSpend.asRupiah
    }

    var spendComparison: SpendComparison? {
        let current = monthSpend
        let previous = previousMonthSpend
        let previousLabel = isCurrentMonth ? "last month" : "the previous month"

        if previous == 0 {
            if current == 0 {
                return nil
            }
            return SpendComparison(
                text: "No spending in \(previousLabel) to compare",
                systemImage: "minus"
            )
        }

        let percent = Int((Double(current - previous) / Double(previous) * 100).rounded())

        if percent == 0 {
            return SpendComparison(
                text: "Same spend as \(previousLabel)",
                systemImage: "equal"
            )
        }

        if percent < 0 {
            return SpendComparison(
                text: "\(abs(percent))% spend below \(previousLabel)",
                systemImage: "arrow.down.right"
            )
        }

        return SpendComparison(
            text: "\(percent)% spend above \(previousLabel)",
            systemImage: "arrow.up.right"
        )
    }

    func goToPreviousMonth() {
        guard canGoToPreviousMonth,
              let previous = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) else {
            return
        }
        selectedMonth = Self.startOfMonth(previous)
    }

    func goToNextMonth() {
        guard canGoToNextMonth,
              let next = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) else {
            return
        }
        selectedMonth = Self.startOfMonth(next)
    }

    func goToCurrentMonth() {
        selectedMonth = Self.startOfMonth(Date())
    }

    func clampSelectedMonthIfNeeded() {
        let current = Self.startOfMonth(Date())
        if Calendar.current.compare(selectedMonth, to: current, toGranularity: .month) == .orderedDescending {
            selectedMonth = current
        } else if Calendar.current.compare(selectedMonth, to: earliestMonth, toGranularity: .month) == .orderedAscending {
            selectedMonth = earliestMonth
        }
    }

    private var monthTransactions: [TransactionModel] {
        transactions.filter {
            Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var monthBalance: Int {
        monthTransactions.reduce(0) {
            $0 + ($1.category.type == .income ? $1.amount : -$1.amount)
        }
    }

    private var monthIncome: Int {
        monthTransactions
            .filter { $0.category.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthSpend: Int {
        monthTransactions
            .filter { $0.category.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    var budgetStatuses: [CategoryBudgetStatus] {
        categories.values
            .compactMap { category in
                let spent = monthTransactions
                    .filter { $0.category.id == category.id }
                    .reduce(0) { $0 + $1.amount }
                return CategoryBudgetStatus.from(category: category, spent: spent)
            }
            .sorted { lhs, rhs in
                if lhs.isOver != rhs.isOver {
                    return lhs.isOver && !rhs.isOver
                }
                return lhs.progress > rhs.progress
            }
    }

    var overBudgetCount: Int {
        budgetStatuses.filter(\.isOver).count
    }

    private var previousMonthSpend: Int {
        guard let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) else {
            return 0
        }

        return transactions
            .filter {
                Calendar.current.isDate($0.date, equalTo: previousMonth, toGranularity: .month)
                    && $0.category.type == .expense
            }
            .reduce(0) { $0 + $1.amount }
    }

    private var earliestMonth: Date {
        let current = Self.startOfMonth(Date())
        guard let oldest = transactions.map(\.date).min() else {
            return current
        }
        return min(Self.startOfMonth(oldest), current)
    }

    private static func startOfMonth(_ date: Date) -> Date {
        Calendar.current.dateInterval(of: .month, for: date)?.start ?? date
    }

    // MARK: - Firebase

    private func fetchUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .getDocument { [weak self] snap, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = AppErrorMapper.message(for: error)
                        return
                    }
                    self?.userName = snap?.data()?["name"] as? String ?? "User"
                }
            }
    }

    func fetchCategoriesAndTransactions() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listenCategories(uid: uid)
    }

    private func listenCategories(uid: String) {
        categoryListener?.remove()

        categoryListener = db.collection("users")
            .document(uid)
            .collection("categories")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = AppErrorMapper.message(for: error)
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
                    if map.isEmpty && !self.didAttemptDefaultSeed {
                        self.didAttemptDefaultSeed = true
                        DefaultCategorySeeder.seedIfNeeded(for: uid) { [weak self] error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    self?.errorMessage = AppErrorMapper.message(for: error)
                                    self?.categories = [:]
                                    self?.listenTransactions(uid: uid)
                                    return
                                }
                                self?.fetchCategoriesAndTransactions()
                            }
                        }
                        return
                    }

                    self.categories = map
                    if !map.isEmpty {
                        DefaultCategorySeeder.markSeeded(for: uid)
                    }
                    self.applyCategoriesToTransactions()
                    WidgetSnapshotStore.save(transactions: self.transactions)
                    if self.transactionListener == nil {
                        self.listenTransactions(uid: uid)
                    }
                }
            }
    }

    private func applyCategoriesToTransactions() {
        transactions = transactions.map { transaction in
            guard let updated = categories[transaction.category.id] else {
                return transaction
            }
            return TransactionModel(
                id: transaction.id,
                title: transaction.title,
                note: transaction.note,
                amount: transaction.amount,
                date: transaction.date,
                category: updated,
                recurringId: transaction.recurringId
            )
        }
    }

    private func listenTransactions(uid: String) {
        transactionListener?.remove()

        transactionListener = db.collection("users")
            .document(uid)
            .collection("transactions")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = AppErrorMapper.message(for: error)
                    }
                    return
                }

                let parsed = snapshot?.documents.compactMap {
                    TransactionModel.from(document: $0, categories: self.categories)
                } ?? []

                DispatchQueue.main.async {
                    self.transactions = parsed
                    WidgetSnapshotStore.save(transactions: parsed)
                }
            }
    }
}
