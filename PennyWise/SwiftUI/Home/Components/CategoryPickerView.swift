//
//  CategoryPickerView.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/01/26.
//

import SwiftUI

struct CategoryPickerView: View {

    let isIncome: Bool
    @Binding var selectedCategory: CategoryModel?
    @Binding var isPresented: Bool

    @StateObject private var viewModel = AddTransactionViewModel()
    @State private var showAddCategory = false
    @State private var categoryToEdit: CategoryModel?
    @State private var categoryPendingDelete: CategoryModel?
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                AppBackgroundView()

                List(viewModel.filteredCategories(isIncome: isIncome)) { category in
                    Button {
                        selectedCategory = category
                        isPresented = false
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 10, height: 10)

                            if selectedCategory?.id == category.id {
                                Text(category.name)
                                    .bold()
                            } else {
                                Text(category.name)
                            }

                            Spacer()

                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                            }
                        }
                        .foregroundColor(Color.appInk)
                    }
                    .listRowBackground(Color.appBackground)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            categoryPendingDelete = category
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            categoryToEdit = category
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Color.appMuted)
                    }
                }
                .listStyle(.plain)
                .background(Color.appBackground)
                .padding(.bottom, 80)

                VStack {
                    Button {
                        showAddCategory = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Category")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appAccent)
                        .foregroundColor(Color.appOnAccent)
                        .cornerRadius(14)
                    }
                }
                .padding()
                .background(
                    Color.appCard
                        .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
                )
            }
            .navigationTitle("Select \(isIncome ? "Income" : "Expense") Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isPresented = false } label: { Text("Close") .foregroundColor(Color.appInk) }
                }
            }
            .confirmationDialog(
                "Delete Category",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deletePendingCategory()
                }
                Button("Cancel", role: .cancel) {
                    categoryPendingDelete = nil
                }
            } message: {
                Text("Existing transactions keep their history. This cannot be undone.")
            }
            .alert(isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? AppErrorMapper.genericMessage),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView(
                isPresented: $showAddCategory,
                initialType: isIncome ? .income : .expense
            ) { _ in
                viewModel.fetchCategories()
            }
        }
        .sheet(item: $categoryToEdit) { category in
            AddCategoryView(
                isPresented: Binding(
                    get: { categoryToEdit != nil },
                    set: { if !$0 { categoryToEdit = nil } }
                ),
                categoryToEdit: category
            ) { result in
                handleCategoryChange(result)
            }
        }
    }

    private func handleCategoryChange(_ result: CategoryFormResult) {
        viewModel.fetchCategories()

        switch result {
        case .saved(let category):
            if selectedCategory?.id == category.id {
                if category.type == (isIncome ? .income : .expense) {
                    selectedCategory = category
                } else {
                    selectedCategory = nil
                }
            }
        case .deleted(let id):
            if selectedCategory?.id == id {
                selectedCategory = nil
            }
        }
    }

    private func deletePendingCategory() {
        guard let category = categoryPendingDelete else { return }

        CategoryService.delete(id: category.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    errorMessage = AppErrorMapper.message(for: error)
                case .success:
                    handleCategoryChange(.deleted(category.id))
                }
                categoryPendingDelete = nil
            }
        }
    }
}
