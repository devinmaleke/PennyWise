//
//  CategorySummaryModel.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import Foundation
import FirebaseFirestore

struct CategoryModel: Identifiable, Hashable {
    let id: String
    let name: String
    let type: CategoryType
    let colorHex: String
    let monthlyBudget: Int

    var hasBudget: Bool {
        type == .expense && monthlyBudget > 0
    }
}

enum CategoryType: String, Hashable {
    case income
    case expense
}

extension CategoryModel {

    static func from(document: QueryDocumentSnapshot) -> CategoryModel? {
        from(id: document.documentID, data: document.data())
    }

    static func from(id: String, data: [String: Any]) -> CategoryModel? {
        guard
            let name = data["name"] as? String,
            let typeString = data["type"] as? String,
            let type = CategoryType(rawValue: typeString)
        else {
            return nil
        }

        return CategoryModel(
            id: id,
            name: name,
            type: type,
            colorHex: data["colorHex"] as? String ?? "#1D2E3E",
            monthlyBudget: max(FirestoreValue.int(data["monthlyBudget"]) ?? 0, 0)
        )
    }
}

struct CategoryBudgetStatus: Identifiable {
    let id: String
    let name: String
    let colorHex: String
    let spent: Int
    let budget: Int

    var remaining: Int { max(budget - spent, 0) }
    var overAmount: Int { max(spent - budget, 0) }
    var isOver: Bool { spent > budget }

    var progress: Double {
        guard budget > 0 else { return 0 }
        return min(Double(spent) / Double(budget), 1)
    }

    static func from(category: CategoryModel, spent: Int) -> CategoryBudgetStatus? {
        guard category.hasBudget else { return nil }
        return CategoryBudgetStatus(
            id: category.id,
            name: category.name,
            colorHex: category.colorHex,
            spent: spent,
            budget: category.monthlyBudget
        )
    }
}
