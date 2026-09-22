//
//  DefaultCategorySeeder.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import FirebaseFirestore

enum DefaultCategorySeeder {

    private static let defaults: [(name: String, type: CategoryType, colorHex: String)] = [
        ("Food", .expense, "#E74C3C"),
        ("Transport", .expense, "#3498DB"),
        ("Shopping", .expense, "#9B59B6"),
        ("Bills", .expense, "#E67E22"),
        ("Health", .expense, "#1ABC9C"),
        ("Other", .expense, "#1D2E3E"),
        ("Salary", .income, "#27AE60"),
        ("Bonus", .income, "#2ECC71"),
        ("Other", .income, "#466C85")
    ]

    static func markSeeded(for uid: String) {
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(["categoriesSeeded": true], merge: true)
    }

    static func seedIfNeeded(
        for uid: String,
        completion: @escaping (Error?) -> Void
    ) {
        let userRef = Firestore.firestore()
            .collection("users")
            .document(uid)
        let collection = userRef.collection("categories")

        userRef.getDocument { userSnapshot, error in
            if let error = error {
                completion(error)
                return
            }

            if (userSnapshot?.data()?["categoriesSeeded"] as? Bool) == true {
                completion(nil)
                return
            }

            collection.limit(to: 1).getDocuments { snapshot, error in
                if let error = error {
                    completion(error)
                    return
                }

                if snapshot?.documents.isEmpty == false {
                    markSeeded(for: uid)
                    completion(nil)
                    return
                }

                let batch = Firestore.firestore().batch()

                defaults.forEach { item in
                    let reference = collection.document()
                    batch.setData([
                        "name": item.name,
                        "type": item.type.rawValue,
                        "colorHex": item.colorHex,
                        "createdAt": Timestamp()
                    ], forDocument: reference)
                }

                batch.commit { error in
                    if error == nil {
                        markSeeded(for: uid)
                    }
                    completion(error)
                }
            }
        }
    }
}
