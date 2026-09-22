//
//  AddCategoryView.swift
//  PennyWise
//
//  Created by Devin Maleke on 02/02/26.
//

import SwiftUI

struct AddCategoryView: View {

    @Binding var isPresented: Bool
    var categoryToEdit: CategoryModel? = nil
    var initialType: CategoryType = .expense
    var onCompleted: (CategoryFormResult) -> Void = { _ in }

    @State private var name = ""
    @State private var type: CategoryType = .expense
    @State private var colorHex = "#1D2E3E"
    @State private var budget = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false
    @State private var didPrefill = false

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
            VStack(spacing: 20) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        inputField(
                            title: "Category Name",
                            text: $name,
                            keyboard: .default
                        )

                        HStack {
                            Text("Category Type")
                                .bold()
                                .foregroundColor(Color.appInk)
                            Spacer()
                        }

                        Picker("Type", selection: $type) {
                            Text("Expense").tag(CategoryType.expense)
                            Text("Income").tag(CategoryType.income)
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        CategoryColorPicker(selectedHex: $colorHex)

                        if type == .expense {
                            AmountInputField(
                                title: "Monthly budget (optional)",
                                text: $budget
                            )
                        }
                    }
                }

                Button {
                    saveCategory()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.appOnAccent))
                        }
                        Text(categoryToEdit == nil ? "Save" : "Save Changes")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appAccent)
                    .foregroundColor(Color.appOnAccent)
                    .cornerRadius(14)
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving ? 0.5 : 1)

                if categoryToEdit != nil {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete Category")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(14)
                    }
                    .disabled(isSaving)
                }
            }
            .padding()
            }
            .navigationTitle(categoryToEdit == nil ? "Add Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isPresented = false } label: { Text("Close") .foregroundColor(Color.appInk) }
                }
            }
            .alert(isPresented: errorAlertBinding) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? AppErrorMapper.genericMessage),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = nil
                    }
                )
            }
            .confirmationDialog(
                "Delete Category",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteCategory()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Existing transactions keep their history. This cannot be undone.")
            }
            .onAppear {
                prefillIfNeeded()
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func prefillIfNeeded() {
        guard !didPrefill else { return }
        didPrefill = true

        if let category = categoryToEdit {
            name = category.name
            type = category.type
            colorHex = category.colorHex.isEmpty ? "#1D2E3E" : category.colorHex
            if category.monthlyBudget > 0 {
                budget = AmountParser.grouped(category.monthlyBudget)
            }
            return
        }

        type = initialType
        colorHex = initialType == .income ? "#27AE60" : "#1D2E3E"
    }

    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        isSaving = true
        let monthlyBudget = type == .expense ? (AmountParser.parse(budget) ?? 0) : 0

        if let category = categoryToEdit {
            let updated = CategoryModel(
                id: category.id,
                name: trimmedName,
                type: type,
                colorHex: colorHex,
                monthlyBudget: monthlyBudget
            )

            CategoryService.update(updated) { result in
                DispatchQueue.main.async {
                    isSaving = false
                    switch result {
                    case .failure(let error):
                        errorMessage = AppErrorMapper.message(for: error)
                    case .success(let saved):
                        onCompleted(.saved(saved))
                        isPresented = false
                    }
                }
            }
            return
        }

        CategoryService.create(
            name: trimmedName,
            type: type,
            colorHex: colorHex,
            monthlyBudget: monthlyBudget
        ) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .failure(let error):
                    errorMessage = AppErrorMapper.message(for: error)
                case .success(let saved):
                    onCompleted(.saved(saved))
                    isPresented = false
                }
            }
        }
    }

    private func deleteCategory() {
        guard let category = categoryToEdit else { return }

        isSaving = true
        CategoryService.delete(id: category.id) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .failure(let error):
                    errorMessage = AppErrorMapper.message(for: error)
                case .success:
                    onCompleted(.deleted(category.id))
                    isPresented = false
                }
            }
        }
    }
}
