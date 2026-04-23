//
//  OptionsModel.swift
//  PennyWise
//
//  Created by Samir iOS on 20/01/26.
//

import Foundation

enum Options: String, CaseIterable, Identifiable {
    case income = "Income"
    case expense = "Expense"

    var id: String { rawValue }

    var transactionType: CategoryType {
        switch self {
        case .income: return .income
        case .expense: return .expense
        }
    }
}

