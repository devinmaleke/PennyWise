//
//  AddTransactionViewModel.swift
//  PennyWise
//
//  Created by Devin Maleke on 02/02/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum TransactionFormResult {
    case saved(TransactionModel)
    case deleted(String)
}

final class AddTransactionViewModel: ObservableObject {

    @Published var categories: [CategoryModel] = []
    @Published var selectedCategory: CategoryModel?
    @Published var showAddCategory = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var didAttemptDefaultSeed = false
    private var editingTransactionId: String?
    private var editingRecurringId = ""

    var isEditing: Bool {
        editingTransactionId != nil
    }

    init() {
        fetchCategories()
    }

    func beginEditing(_ transaction: TransactionModel) {
        editingTransactionId = transaction.id
        editingRecurringId = transaction.recurringId
        selectedCategory = matchingCategory(for: transaction.category)
    }

    func beginRepeat(_ transaction: TransactionModel) {
        beginRepeat(category: transaction.category)
    }

    func beginRepeat(category: CategoryModel) {
        editingTransactionId = nil
        editingRecurringId = ""
        selectedCategory = matchingCategory(for: category)
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
                        self?.errorMessage = AppErrorMapper.message(for: error)
                    }
                    return
                }

                let list = snap?.documents.compactMap { CategoryModel.from(document: $0) } ?? []

                DispatchQueue.main.async {
                    if list.isEmpty && !(self?.didAttemptDefaultSeed ?? true) {
                        self?.didAttemptDefaultSeed = true
                        DefaultCategorySeeder.seedIfNeeded(for: uid) { error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    self?.errorMessage = AppErrorMapper.message(for: error)
                                    self?.categories = []
                                    return
                                }
                                self?.fetchCategories()
                            }
                        }
                        return
                    }

                    self?.categories = list
                    if let selected = self?.selectedCategory {
                        self?.selectedCategory = list.first(where: { $0.id == selected.id }) ?? selected
                    }
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
        note: String,
        frequency: RecurringFrequency? = nil,
        completion: @escaping (TransactionModel) -> Void
    ) {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let category = selectedCategory
        else {
            errorMessage = "Category not selected"
            return
        }

        isLoading = true

        let writeTransaction: (String, String?) -> Void = { [weak self] recurringId, occurrenceId in
            self?.writeTransaction(
                uid: uid,
                title: title,
                amount: amount,
                date: date,
                isIncome: isIncome,
                note: note,
                category: category,
                recurringId: recurringId,
                occurrenceId: occurrenceId,
                completion: completion
            )
        }

        guard let frequency = frequency, editingTransactionId == nil else {
            writeTransaction(editingRecurringId, nil)
            return
        }

        RecurringService.create(
            title: title,
            note: note,
            amount: amount,
            date: date,
            category: category,
            frequency: frequency
        ) { [weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = AppErrorMapper.message(for: error)
                }
            case .success(let template):
                writeTransaction(
                    template.id,
                    RecurringService.occurrenceId(templateId: template.id, date: date)
                )
            }
        }
    }

    private func writeTransaction(
        uid: String,
        title: String,
        amount: Int,
        date: Date,
        isIncome: Bool,
        note: String,
        category: CategoryModel,
        recurringId: String,
        occurrenceId: String?,
        completion: @escaping (TransactionModel) -> Void
    ) {
        var data = transactionData(
            title: title,
            amount: amount,
            date: date,
            isIncome: isIncome,
            category: category,
            note: note,
            recurringId: recurringId,
            occurrenceId: occurrenceId
        )

        let collection = db.collection("users")
            .document(uid)
            .collection("transactions")

        let finish: (String) -> Void = { transactionId in
            completion(
                TransactionModel(
                    id: transactionId,
                    title: title,
                    note: note,
                    amount: amount,
                    date: date,
                    category: category,
                    recurringId: recurringId
                )
            )
        }

        if let transactionId = editingTransactionId {
            data["updatedAt"] = Timestamp(date: Date())

            collection.document(transactionId).updateData(data) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false

                    if let error = error {
                        self?.errorMessage = AppErrorMapper.message(for: error)
                        return
                    }

                    finish(transactionId)
                }
            }
            return
        }

        data["createdAt"] = Timestamp(date: Date())
        let reference = collection.document()

        reference.setData(data) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = AppErrorMapper.message(for: error)
                }
                return
            }

            let complete = {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    finish(reference.documentID)
                }
            }

            if recurringId.isEmpty {
                complete()
            } else {
                RecurringService.generateDueIfNeeded { _ in
                    complete()
                }
            }
        }
    }

    func deleteTransaction(completion: @escaping () -> Void) {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let transactionId = editingTransactionId
        else {
            errorMessage = AppErrorMapper.genericMessage
            return
        }

        isLoading = true

        db.collection("users")
            .document(uid)
            .collection("transactions")
            .document(transactionId)
            .delete { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false

                    if let error = error {
                        self?.errorMessage = AppErrorMapper.message(for: error)
                        return
                    }

                    completion()
                }
            }
    }

    private func matchingCategory(for category: CategoryModel) -> CategoryModel {
        categories.first(where: { $0.id == category.id }) ?? category
    }

    private func transactionData(
        title: String,
        amount: Int,
        date: Date,
        isIncome: Bool,
        category: CategoryModel,
        note: String,
        recurringId: String,
        occurrenceId: String?
    ) -> [String: Any] {
        var data: [String: Any] = [
            "title": title,
            "note": note,
            "amount": amount,
            "isIncome": isIncome,
            "categoryId": category.id,
            "categoryName": category.name,
            "categoryType": category.type.rawValue,
            "categoryColor": category.colorHex,
            "date": Timestamp(date: date)
        ]
        if !recurringId.isEmpty {
            data["recurringId"] = recurringId
        }
        if let occurrenceId = occurrenceId {
            data["recurringOccurrenceId"] = occurrenceId
        }
        return data
    }
}
