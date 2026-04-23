//
//  HomeViewModel.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case income = "Income"
    case expense = "Expense"
}

final class HomeViewModel: ObservableObject {

    @Published var userName: String = ""
    @Published var categories: [String: CategoryModel] = [:]
    @Published var transactions: [TransactionModel] = []
    @Published var selectedFilter: TransactionFilter = .all

    private let db = Firestore.firestore()

    init() {
        fetchUser()
        fetchCategoriesAndTransactions()
    }

    // MARK: - Computed
    var filteredTransactions: [TransactionModel] {
        switch selectedFilter {
        case .all:
            return transactions
        case .income:
            return transactions.filter { $0.category.type == .income }
        case .expense:
            return transactions.filter { $0.category.type == .expense }
        }
    }

    var balanceFormatted: String {
        let total = transactions.reduce(0) {
            $0 + ($1.category.type == .income ? $1.amount : -$1.amount)
        }
        return format(total)
    }

    // MARK: - Firebase

    private func fetchUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .getDocument { [weak self] snap, _ in
                self?.userName = snap?.data()?["name"] as? String ?? "User"
            }
    }

    /// Fetch categories FIRST, then listen transactions
    func fetchCategoriesAndTransactions() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .collection("categories")
            .getDocuments { [weak self] snapshot, error in

                guard let self = self else { return }

                if let error = error {
                    print("Fetch categories error:", error.localizedDescription)
                    return
                }

                var map: [String: CategoryModel] = [:]

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    guard
                        let name = data["name"] as? String,
                        let typeString = data["type"] as? String,
                        let type = CategoryType(rawValue: typeString)
                    else { return }

                    let category = CategoryModel(
                        id: doc.documentID,
                        name: name,
                        type: type,
                        colorHex: data["colorHex"] as? String ?? "#000000"
                    )

                    map[category.id] = category
                }

                DispatchQueue.main.async {
                    self.categories = map
                    self.listenTransactions(uid: uid)
                }
            }
    }

    private func listenTransactions(uid: String) {
        db.collection("users")
            .document(uid)
            .collection("transactions")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in

                guard let self = self else { return }

                self.transactions = snapshot?.documents.compactMap { doc in
                    let data = doc.data()

                    guard
                        let amount = data["amount"] as? Int,
                        let categoryId = data["categoryId"] as? String,
                        let category = self.categories[categoryId],
                        let timestamp = data["date"] as? Timestamp
                    else { return nil }

                    return TransactionModel(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        amount: amount,
                        date: timestamp.dateValue(),
                        category: category
                    )
                } ?? []
            }
    }

    // MARK: - Formatter
    private func format(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "IDR"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "Rp \(value)"
    }
}
