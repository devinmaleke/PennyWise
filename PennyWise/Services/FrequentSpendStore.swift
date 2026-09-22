//
//  FrequentSpendStore.swift
//  PennyWise
//
//  Created by Devin Maleke on 22/09/26.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

enum FrequentSpendError: LocalizedError {
    case limitReached

    var errorDescription: String? {
        "You can pin up to 8 frequent spends"
    }
}

final class FrequentSpendStore: ObservableObject {

    static let shared = FrequentSpendStore()
    static let maxCount = 8

    @Published private(set) var items: [FrequentSpend] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func start() {
        stop()
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener = collection(uid: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                if error != nil {
                    return
                }

                let parsed = (snapshot?.documents.compactMap(FrequentSpend.from) ?? [])
                    .sorted { $0.createdAt > $1.createdAt }
                DispatchQueue.main.async {
                    self?.items = parsed
                }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
        items = []
    }

    func isPinned(title: String, categoryId: String) -> Bool {
        item(title: title, categoryId: categoryId) != nil
    }

    func item(title: String, categoryId: String) -> FrequentSpend? {
        let fingerprint = FrequentSpend.fingerprint(title: title, categoryId: categoryId)
        return items.first {
            FrequentSpend.fingerprint(title: $0.title, categoryId: $0.category.id) == fingerprint
        }
    }

    func pin(
        title: String,
        note: String,
        lastAmount: Int,
        category: CategoryModel,
        completion: @escaping (Error?) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(missingUserError)
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            completion(nil)
            return
        }

        let fingerprint = FrequentSpend.fingerprint(title: trimmedTitle, categoryId: category.id)
        let noteValue = note.trimmingCharacters(in: .whitespacesAndNewlines)

        collection(uid: uid).getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(error)
                return
            }

            let existing = snapshot?.documents.compactMap(FrequentSpend.from) ?? []
            let alreadyPinned = existing.contains {
                FrequentSpend.fingerprint(title: $0.title, categoryId: $0.category.id) == fingerprint
            }

            if alreadyPinned {
                completion(nil)
                return
            }

            if existing.count >= FrequentSpendStore.maxCount {
                completion(FrequentSpendError.limitReached)
                return
            }

            self?.collection(uid: uid).document().setData([
                "title": trimmedTitle,
                "note": noteValue,
                "lastAmount": lastAmount,
                "categoryId": category.id,
                "categoryName": category.name,
                "categoryType": category.type.rawValue,
                "categoryColor": category.colorHex,
                "fingerprint": fingerprint,
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ], completion: completion)
        }
    }

    func unpin(id: String, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(missingUserError)
            return
        }

        collection(uid: uid).document(id).delete(completion: completion)
    }

    func unpin(title: String, categoryId: String, completion: @escaping (Error?) -> Void) {
        guard let item = item(title: title, categoryId: categoryId) else {
            completion(nil)
            return
        }
        unpin(id: item.id, completion: completion)
    }

    func recordUse(title: String, categoryId: String, amount: Int) {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let item = item(title: title, categoryId: categoryId)
        else {
            return
        }

        collection(uid: uid)
            .document(item.id)
            .updateData([
                "lastAmount": amount,
                "updatedAt": Timestamp(date: Date())
            ])
    }

    private func collection(uid: String) -> CollectionReference {
        db.collection("users")
            .document(uid)
            .collection("frequentSpends")
    }

    private var missingUserError: NSError {
        NSError(
            domain: "FrequentSpendStore",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Please log in again to continue"]
        )
    }
}
