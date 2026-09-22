//
//  CategoryService.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum CategoryFormResult {
    case saved(CategoryModel)
    case deleted(String)
}

enum CategoryService {

    static func create(
        name: String,
        type: CategoryType,
        colorHex: String = "#1D2E3E",
        monthlyBudget: Int = 0,
        completion: @escaping (Result<CategoryModel, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(missingUserError))
            return
        }

        let collection = categoriesCollection(uid: uid)
        let reference = collection.document()
        let budget = type == .expense ? max(monthlyBudget, 0) : 0
        let data: [String: Any] = [
            "name": name,
            "type": type.rawValue,
            "colorHex": colorHex,
            "monthlyBudget": budget,
            "createdAt": Timestamp()
        ]

        reference.setData(data) { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            DefaultCategorySeeder.markSeeded(for: uid)
            completion(.success(
                CategoryModel(
                    id: reference.documentID,
                    name: name,
                    type: type,
                    colorHex: colorHex,
                    monthlyBudget: budget
                )
            ))
        }
    }

    static func update(
        _ category: CategoryModel,
        completion: @escaping (Result<CategoryModel, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(missingUserError))
            return
        }

        let data: [String: Any] = [
            "name": category.name,
            "type": category.type.rawValue,
            "colorHex": category.colorHex,
            "monthlyBudget": category.type == .expense ? max(category.monthlyBudget, 0) : 0,
            "updatedAt": Timestamp()
        ]

        categoriesCollection(uid: uid)
            .document(category.id)
            .updateData(data) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                syncTransactions(uid: uid, category: category) { syncError in
                    if let syncError = syncError {
                        completion(.failure(syncError))
                        return
                    }
                    RecurringService.syncCategory(uid: uid, category: category) { recurringError in
                        if let recurringError = recurringError {
                            completion(.failure(recurringError))
                            return
                        }
                        completion(.success(category))
                    }
                }
            }
    }

    static func delete(
        id: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(missingUserError))
            return
        }

        categoriesCollection(uid: uid)
            .document(id)
            .delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
    }

    private static func syncTransactions(
        uid: String,
        category: CategoryModel,
        completion: @escaping (Error?) -> Void
    ) {
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("transactions")
            .whereField("categoryId", isEqualTo: category.id)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(error)
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(nil)
                    return
                }

                let db = Firestore.firestore()
                let chunks = stride(from: 0, to: documents.count, by: 450).map {
                    Array(documents[$0..<min($0 + 450, documents.count)])
                }

                func commit(_ remaining: [[QueryDocumentSnapshot]]) {
                    guard let chunk = remaining.first else {
                        completion(nil)
                        return
                    }

                    let batch = db.batch()
                    chunk.forEach { document in
                        batch.updateData([
                            "categoryName": category.name,
                            "categoryType": category.type.rawValue,
                            "categoryColor": category.colorHex,
                            "isIncome": category.type == .income
                        ], forDocument: document.reference)
                    }

                    batch.commit { error in
                        if let error = error {
                            completion(error)
                            return
                        }
                        commit(Array(remaining.dropFirst()))
                    }
                }

                commit(chunks)
            }
    }

    private static func categoriesCollection(uid: String) -> CollectionReference {
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("categories")
    }

    private static var missingUserError: NSError {
        NSError(
            domain: "PennyWise",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Please log in again to continue"]
        )
    }
}
