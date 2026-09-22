//
//  SummaryViewModel.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct CategorySlice: Identifiable {
    let id: String
    let name: String
    let amount: Int
    let colorHex: String
    let percent: Double
    let startFraction: Double
    let endFraction: Double
}

final class SummaryViewModel: ObservableObject {

    @Published var transactions: [TransactionModel] = []
    @Published var categories: [String: CategoryModel] = [:]
    @Published var selectedPeriod: FilterPeriod = .thisMonth
    @Published var selectedType: CategoryType = .expense
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?
    private var categoryListener: ListenerRegistration?

    private let fallbackColors = [
        "#E74C3C", "#3498DB", "#9B59B6", "#E67E22",
        "#1ABC9C", "#27AE60", "#F1C40F", "#466C85"
    ]

    init() {
        startListening()
        startListeningCategories()
    }

    deinit {
        listener?.remove()
        categoryListener?.remove()
    }

    var periodTransactions: [TransactionModel] {
        transactions.filter { transaction in
            if let range = selectedPeriod.dateRange {
                return transaction.date >= range.start && transaction.date <= range.end
            }
            return true
        }
    }

    var incomeTotal: Int {
        periodTransactions
            .filter { $0.category.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    var spendTotal: Int {
        periodTransactions
            .filter { $0.category.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    var netTotal: Int {
        incomeTotal - spendTotal
    }

    var incomeShare: Double {
        let total = incomeTotal + spendTotal
        guard total > 0 else { return 0 }
        return Double(incomeTotal) / Double(total)
    }

    var spendShare: Double {
        let total = incomeTotal + spendTotal
        guard total > 0 else { return 0 }
        return Double(spendTotal) / Double(total)
    }

    var breakdownTotal: Int {
        selectedType == .income ? incomeTotal : spendTotal
    }

    var slices: [CategorySlice] {
        slices(for: selectedType)
    }

    func slices(for type: CategoryType) -> [CategorySlice] {
        let items = Dictionary(grouping: periodTransactions.filter { $0.category.type == type }) {
            $0.category
        }
        .map { category, list -> (category: CategoryModel, amount: Int) in
            let live = categories[category.id] ?? category
            return (live, list.reduce(0) { $0 + $1.amount })
        }
        .sorted { $0.amount > $1.amount }

        let total = items.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        var cursor: Double = 0
        return items.enumerated().map { index, item in
            let percent = Double(item.amount) / Double(total)
            let start = cursor
            cursor += percent
            return CategorySlice(
                id: item.category.id,
                name: item.category.name,
                amount: item.amount,
                colorHex: resolvedColor(item.category.colorHex, index: index),
                percent: percent,
                startFraction: start,
                endFraction: cursor
            )
        }
    }

    var shareText: String {
        var lines = [
            "PennyWise",
            selectedPeriod.rawValue,
            "",
            "Net \(netTotal.asRupiah)",
            "Income \(incomeTotal.asRupiah)",
            "Spent \(spendTotal.asRupiah)"
        ]

        let expenses = Array(slices(for: .expense).prefix(5))
        if !expenses.isEmpty {
            lines.append("")
            lines.append("Top expenses")
            expenses.forEach { slice in
                lines.append("• \(slice.name) — \(slice.amount.asRupiah) (\(Int((slice.percent * 100).rounded()))%)")
            }
        }

        let income = Array(slices(for: .income).prefix(5))
        if !income.isEmpty {
            lines.append("")
            lines.append("Top income")
            income.forEach { slice in
                lines.append("• \(slice.name) — \(slice.amount.asRupiah) (\(Int((slice.percent * 100).rounded()))%)")
            }
        }

        return lines.joined(separator: "\n")
    }

    func budgetStatus(for slice: CategorySlice) -> CategoryBudgetStatus? {
        guard selectedPeriod == .thisMonth, selectedType == .expense else { return nil }
        guard let category = categories[slice.id] else { return nil }
        return CategoryBudgetStatus.from(category: category, spent: slice.amount)
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

    private func resolvedColor(_ hex: String, index: Int) -> String {
        let normalized = hex.lowercased()
        if normalized == "#000000" || normalized == "#1d2e3e" || hex.isEmpty {
            return fallbackColors[index % fallbackColors.count]
        }
        return hex
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
}
