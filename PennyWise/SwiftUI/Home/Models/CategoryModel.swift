//
//  CategorySummaryModel.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import Foundation

struct CategoryModel: Identifiable, Hashable {
    let id: String
    let name: String
    let type: CategoryType   // income / expense
    let colorHex: String
}

enum CategoryType: String {
    case income
    case expense
}
