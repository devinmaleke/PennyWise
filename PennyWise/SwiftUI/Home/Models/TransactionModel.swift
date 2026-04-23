//
//  TransactionModel.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import Foundation

struct TransactionModel: Identifiable {
    let id: String
    let title: String
    let amount: Int
    let date: Date
    let category: CategoryModel
}
