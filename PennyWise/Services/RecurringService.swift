//
//  RecurringService.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum RecurringService {

    private static var isGenerating = false

    static func create(
        title: String,
        note: String,
        amount: Int,
        date: Date,
        category: CategoryModel,
        frequency: RecurringFrequency,
        completion: @escaping (Result<RecurringTemplate, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(missingUserError))
            return
        }

        let nextDate = frequency.nextDate(after: Calendar.current.startOfDay(for: date))
        let reference = collection(uid: uid).document()
        let template = RecurringTemplate(
            id: reference.documentID,
            title: title,
            note: note,
            amount: amount,
            category: category,
            isIncome: category.type == .income,
            frequency: frequency,
            nextDate: nextDate,
            isActive: true
        )

        reference.setData(firestoreData(for: template, created: true)) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(template))
        }
    }

    static func update(
        _ template: RecurringTemplate,
        completion: @escaping (Result<RecurringTemplate, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(missingUserError))
            return
        }

        collection(uid: uid)
            .document(template.id)
            .updateData(firestoreData(for: template, created: false)) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(template))
            }
    }

    static func setActive(
        _ template: RecurringTemplate,
        isActive: Bool,
        completion: @escaping (Error?) -> Void
    ) {
        var nextDate = template.nextDate
        if isActive {
            nextDate = nextFutureDate(from: template.nextDate, frequency: template.frequency)
        }

        let updated = RecurringTemplate(
            id: template.id,
            title: template.title,
            note: template.note,
            amount: template.amount,
            category: template.category,
            isIncome: template.isIncome,
            frequency: template.frequency,
            nextDate: nextDate,
            isActive: isActive
        )

        update(updated) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success:
                if isActive {
                    generateDueIfNeeded(completion: completion)
                } else {
                    completion(nil)
                }
            }
        }
    }

    static func delete(
        id: String,
        completion: @escaping (Error?) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(missingUserError)
            return
        }

        collection(uid: uid).document(id).delete(completion: completion)
    }

    static func generateDueIfNeeded(completion: ((Error?) -> Void)? = nil) {
        guard !isGenerating else {
            completion?(nil)
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            completion?(missingUserError)
            return
        }

        isGenerating = true

        collection(uid: uid)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    isGenerating = false
                    completion?(error)
                    return
                }

                let templates = snapshot?.documents.compactMap(RecurringTemplate.from) ?? []
                generate(
                    remaining: templates,
                    uid: uid,
                    completion: { generateError in
                        isGenerating = false
                        completion?(generateError)
                    }
                )
            }
    }

    static func syncCategory(
        uid: String,
        category: CategoryModel,
        completion: @escaping (Error?) -> Void
    ) {
        collection(uid: uid)
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

                let batch = Firestore.firestore().batch()
                documents.forEach { document in
                    batch.updateData([
                        "categoryName": category.name,
                        "categoryType": category.type.rawValue,
                        "categoryColor": category.colorHex,
                        "isIncome": category.type == .income
                    ], forDocument: document.reference)
                }

                batch.commit(completion: completion)
            }
    }

    private static func generate(
        remaining: [RecurringTemplate],
        uid: String,
        completion: @escaping (Error?) -> Void
    ) {
        guard let template = remaining.first else {
            completion(nil)
            return
        }

        generateOccurrences(for: template, uid: uid) { error in
            if let error = error {
                completion(error)
                return
            }
            generate(remaining: Array(remaining.dropFirst()), uid: uid, completion: completion)
        }
    }

    private static func generateOccurrences(
        for template: RecurringTemplate,
        uid: String,
        completion: @escaping (Error?) -> Void
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var next = calendar.startOfDay(for: template.nextDate)
        var created = 0

        func step() {
            guard next <= today, created < 24 else {
                if next != calendar.startOfDay(for: template.nextDate) || created > 0 {
                    collection(uid: uid)
                        .document(template.id)
                        .updateData(["nextDate": Timestamp(date: next)]) { error in
                            completion(error)
                        }
                } else {
                    completion(nil)
                }
                return
            }

            let occurrence = occurrenceId(templateId: template.id, date: next)
            let transactions = Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("transactions")

            transactions
                .whereField("recurringOccurrenceId", isEqualTo: occurrence)
                .limit(to: 1)
                .getDocuments { snapshot, error in
                    if let error = error {
                        completion(error)
                        return
                    }

                    if snapshot?.documents.isEmpty == false {
                        next = template.frequency.nextDate(after: next)
                        created += 1
                        step()
                        return
                    }

                    let reference = transactions.document()
                    reference.setData(
                        transactionData(for: template, date: next, occurrenceId: occurrence)
                    ) { error in
                        if let error = error {
                            completion(error)
                            return
                        }
                        next = template.frequency.nextDate(after: next)
                        created += 1
                        step()
                    }
                }
        }

        step()
    }

    static func occurrenceId(templateId: String, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(templateId)_\(formatter.string(from: Calendar.current.startOfDay(for: date)))"
    }

    private static func nextFutureDate(from date: Date, frequency: RecurringFrequency) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        var next = Calendar.current.startOfDay(for: date)
        var guardCount = 0
        while next < today, guardCount < 48 {
            next = frequency.nextDate(after: next)
            guardCount += 1
        }
        return next
    }

    private static func firestoreData(for template: RecurringTemplate, created: Bool) -> [String: Any] {
        var data: [String: Any] = [
            "title": template.title,
            "note": template.note,
            "amount": template.amount,
            "isIncome": template.isIncome,
            "categoryId": template.category.id,
            "categoryName": template.category.name,
            "categoryType": template.category.type.rawValue,
            "categoryColor": template.category.colorHex,
            "frequency": template.frequency.rawValue,
            "nextDate": Timestamp(date: Calendar.current.startOfDay(for: template.nextDate)),
            "isActive": template.isActive,
            "updatedAt": Timestamp()
        ]
        if created {
            data["createdAt"] = Timestamp()
        }
        return data
    }

    private static func transactionData(
        for template: RecurringTemplate,
        date: Date,
        occurrenceId: String
    ) -> [String: Any] {
        [
            "title": template.title,
            "note": template.note,
            "amount": template.amount,
            "isIncome": template.isIncome,
            "categoryId": template.category.id,
            "categoryName": template.category.name,
            "categoryType": template.category.type.rawValue,
            "categoryColor": template.category.colorHex,
            "date": Timestamp(date: date),
            "recurringId": template.id,
            "recurringOccurrenceId": occurrenceId,
            "createdAt": Timestamp()
        ]
    }

    private static func collection(uid: String) -> CollectionReference {
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("recurring")
    }

    private static var missingUserError: NSError {
        NSError(
            domain: "PennyWise",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Please log in again to continue"]
        )
    }
}
