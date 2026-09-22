//
//  FrequentSpend.swift
//  PennyWise
//
//  Created by Devin Maleke on 22/09/26.
//

import Foundation
import FirebaseFirestore

struct FrequentSpend: Identifiable, Hashable {
    let id: String
    let title: String
    let note: String
    let lastAmount: Int
    let category: CategoryModel
    let createdAt: Date
}

extension FrequentSpend {

    static func from(document: QueryDocumentSnapshot) -> FrequentSpend? {
        let data = document.data()

        guard let categoryId = data["categoryId"] as? String else {
            return nil
        }

        let typeRaw = data["categoryType"] as? String
        let type = CategoryType(rawValue: typeRaw ?? "")
            ?? ((data["isIncome"] as? Bool) == true ? .income : .expense)

        let category = CategoryModel(
            id: categoryId,
            name: data["categoryName"] as? String ?? "Category",
            type: type,
            colorHex: data["categoryColor"] as? String ?? "#1D2E3E",
            monthlyBudget: 0
        )

        return FrequentSpend(
            id: document.documentID,
            title: data["title"] as? String ?? "",
            note: (data["note"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            lastAmount: FirestoreValue.int(data["lastAmount"]) ?? 0,
            category: category,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
        )
    }

    static func fingerprint(title: String, categoryId: String) -> String {
        let normalized = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return "\(categoryId)|\(normalized)"
    }
}

struct QuickAddSource: Identifiable, Hashable {
    let id: String
    let title: String
    let note: String
    let lastAmount: Int
    let category: CategoryModel
    let frequentId: String?

    static func transaction(_ transaction: TransactionModel) -> QuickAddSource {
        QuickAddSource(
            id: "tx-\(transaction.id)",
            title: transaction.title,
            note: transaction.note,
            lastAmount: transaction.amount,
            category: transaction.category,
            frequentId: nil
        )
    }

    static func frequent(_ item: FrequentSpend, lastAmount: Int) -> QuickAddSource {
        QuickAddSource(
            id: "freq-\(item.id)",
            title: item.title,
            note: item.note,
            lastAmount: lastAmount,
            category: item.category,
            frequentId: item.id
        )
    }
}
