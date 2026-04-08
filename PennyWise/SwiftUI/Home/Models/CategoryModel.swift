//
//  CategorySummaryModel.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import Foundation

struct CategoryModel: Identifiable {
    let id = UUID()
    let name: String
    let amount: Int

    var amountFormatted: String {
        "Rp \(amount)"
    }
}
