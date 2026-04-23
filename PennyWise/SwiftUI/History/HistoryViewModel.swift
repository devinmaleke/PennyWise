//
//  HistoryViewModel.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
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
    @Published var selectedType: CategoryType = .expense
    @Published var selectedPeriod: FilterPeriod = .thisWeek

    private var listener: ListenerRegistration?

    init() {
        startListening()
    }

    deinit {
        listener?.remove()
    }

    private func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("transactions")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in

                guard let documents = snapshot?.documents else { return }

                self?.transactions = documents.compactMap { doc in
                    let data = doc.data()
                    
                    guard
                        let title = data["title"] as? String,
                        let amount = data["amount"] as? Int,
                        let timestamp = data["date"] as? Timestamp,
                        let categoryId = data["categoryId"] as? String,
                        let categoryName = data["categoryName"] as? String,
                        let typeRaw = data["categoryType"] as? String,
                        let colorHex = data["categoryColor"] as? String,
                        let type = CategoryType(rawValue: typeRaw)
                    else { return nil }

                    let category = CategoryModel(
                        id: categoryId,
                        name: categoryName,
                        type: type,
                        colorHex: colorHex
                    )

                    return TransactionModel(
                        id: doc.documentID,
                        title: title,
                        amount: amount,
                        date: timestamp.dateValue(),
                        category: category
                    )
                }
            }
    }

    // MARK: - Group by Date

    var groupedTransactions: [(key: String, value: [TransactionModel])] {
        let grouped = Dictionary(grouping: filteredTransactions) {
            formatDate($0.date)
        }

        return grouped.sorted { $0.key > $1.key }
    }

    // MARK: - Total

    var totalAmount: Int {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Formatter

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
    
    var groupedByCategory: [(category: CategoryModel, total: Int)] {
        let grouped = Dictionary(grouping: filteredTransactions) {
            $0.category
        }

        return grouped.map { (category, transactions) in
            let total = transactions.reduce(0) { $0 + $1.amount }
            return (category, total)
        }
        .sorted { $0.total > $1.total }
    }
    
    var filteredTransactions: [TransactionModel] {
        transactions.filter { transaction in
            guard transaction.category.type == selectedType else { return false }
            
            // filter by period
            if let range = selectedPeriod.dateRange {
                return transaction.date >= range.start && transaction.date <= range.end
            }
            return true // allTime = no date filter
        }
    }
    
    func transactions(for category: CategoryModel) -> [TransactionModel] {
        filteredTransactions.filter { $0.category.id == category.id }
    }
}
