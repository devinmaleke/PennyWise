//
//  TransactionModel.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import Foundation
import FirebaseFirestore

struct TransactionModel: Identifiable, Hashable {
    let id: String
    let title: String
    let note: String
    let amount: Int
    let date: Date
    let category: CategoryModel
    let recurringId: String

    var isRecurring: Bool {
        !recurringId.isEmpty
    }
}

extension TransactionModel {

    static func from(
        document: QueryDocumentSnapshot,
        categories: [String: CategoryModel] = [:]
    ) -> TransactionModel? {
        let data = document.data()

        guard
            let amount = FirestoreValue.int(data["amount"]),
            let timestamp = data["date"] as? Timestamp
        else {
            return nil
        }

        guard let category = resolvedCategory(from: data, categories: categories) else {
            return nil
        }

        return TransactionModel(
            id: document.documentID,
            title: data["title"] as? String ?? "",
            note: (data["note"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            date: timestamp.dateValue(),
            category: category,
            recurringId: data["recurringId"] as? String ?? ""
        )
    }

    func matches(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        return title.localizedCaseInsensitiveContains(trimmed)
            || category.name.localizedCaseInsensitiveContains(trimmed)
            || note.localizedCaseInsensitiveContains(trimmed)
    }

    private static func resolvedCategory(
        from data: [String: Any],
        categories: [String: CategoryModel]
    ) -> CategoryModel? {
        if let categoryId = data["categoryId"] as? String,
           let mapped = categories[categoryId] {
            return mapped
        }

        guard
            let categoryId = data["categoryId"] as? String,
            let name = data["categoryName"] as? String,
            let typeRaw = data["categoryType"] as? String,
            let type = CategoryType(rawValue: typeRaw)
        else {
            return nil
        }

        return CategoryModel(
            id: categoryId,
            name: name,
            type: type,
            colorHex: data["categoryColor"] as? String ?? "#000000",
            monthlyBudget: 0
        )
    }
}

extension Array where Element == TransactionModel {
    func groupedByDayDescending() -> [(key: String, value: [TransactionModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: self) {
            calendar.startOfDay(for: $0.date)
        }

        return grouped
            .sorted { $0.key > $1.key }
            .map { day, transactions in
                (
                    key: day.formatted(),
                    value: transactions.sorted { $0.date > $1.date }
                )
            }
    }
}
