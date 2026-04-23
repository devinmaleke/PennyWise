//
//  AddTransactionViewModel.swift
//  PennyWise
//
//  Created by Samir iOS on 02/02/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

final class AddTransactionViewModel: ObservableObject {

    @Published var categories: [CategoryModel] = []
    @Published var selectedCategory: CategoryModel?
    @Published var showAddCategory = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    init() {
        fetchCategories()
    }

    // MARK: - Fetch Categories
    func fetchCategories() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .collection("categories")
            .getDocuments { [weak self] snap, error in

                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = error.localizedDescription
                    }
                    return
                }

                let list = snap?.documents.compactMap { doc -> CategoryModel? in
                    let data = doc.data()
                    
                    print(data)
                    guard
                        let name = data["name"] as? String,
                        let typeString = data["type"] as? String,
                        let type = CategoryType(rawValue: typeString)
                    else { return nil }

                    return CategoryModel(
                        id: doc.documentID,
                        name: name,
                        type: type,
                        colorHex: data["colorHex"] as? String ?? "#000000"
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self?.categories = list
                }
            }
    }

    // MARK: - Category Filter
    func filteredCategories(isIncome: Bool) -> [CategoryModel] {
        let type: CategoryType = isIncome ? .income : .expense
        return categories.filter { $0.type == type }
    }

    func resetCategoryIfNeeded(isIncome: Bool) {
        let type: CategoryType = isIncome ? .income : .expense
        if let selected = selectedCategory, selected.type != type {
            selectedCategory = nil
        }
    }

    // MARK: - Save Transaction
    func saveTransaction(
        title: String,
        amount: Int,
        date: Date,
        isIncome: Bool,
        completion: @escaping () -> Void
    ) {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let category = selectedCategory
        else {
            errorMessage = "Category not selected"
            return
        }

        isLoading = true

        let data: [String: Any] = [
            "title": title,
            "amount": amount,
            "isIncome": isIncome,
            "categoryId": category.id,
            "categoryName": category.name,
            "categoryType": category.type.rawValue,
            "categoryColor": category.colorHex,
            "date": Timestamp(date: date),
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("users")
            .document(uid)
            .collection("transactions")
            .addDocument(data: data) { [weak self] error in

                DispatchQueue.main.async {
                    self?.isLoading = false

                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }

                    completion()
                }
            }
    }
}
