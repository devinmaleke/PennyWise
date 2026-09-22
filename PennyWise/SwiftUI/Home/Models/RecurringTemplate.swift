//
//  RecurringTemplate.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import Foundation
import FirebaseFirestore

enum RecurringFrequency: String, CaseIterable, Identifiable {
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}

struct RecurringTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let note: String
    let amount: Int
    let category: CategoryModel
    let isIncome: Bool
    let frequency: RecurringFrequency
    let nextDate: Date
    let isActive: Bool
}

extension RecurringTemplate {

    static func from(document: QueryDocumentSnapshot) -> RecurringTemplate? {
        let data = document.data()

        guard
            let amount = FirestoreValue.int(data["amount"]),
            let timestamp = data["nextDate"] as? Timestamp,
            let frequencyRaw = data["frequency"] as? String,
            let frequency = RecurringFrequency(rawValue: frequencyRaw)
        else {
            return nil
        }

        let typeRaw = data["categoryType"] as? String
        let type = CategoryType(rawValue: typeRaw ?? "")
            ?? ((data["isIncome"] as? Bool) == true ? .income : .expense)

        let category = CategoryModel(
            id: data["categoryId"] as? String ?? "",
            name: data["categoryName"] as? String ?? "Category",
            type: type,
            colorHex: data["categoryColor"] as? String ?? "#1D2E3E",
            monthlyBudget: 0
        )

        return RecurringTemplate(
            id: document.documentID,
            title: data["title"] as? String ?? "",
            note: (data["note"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            category: category,
            isIncome: type == .income,
            frequency: frequency,
            nextDate: timestamp.dateValue(),
            isActive: data["isActive"] as? Bool ?? true
        )
    }
}
