//
//  CategoryPickerView.swift
//  PennyWise
//
//  Created by Samir iOS on 21/01/26.
//

import SwiftUI

struct CategoryPickerView: View {
    
    let isIncome: Bool
    @Binding var selectedCategory: CategoryModel?
    @Binding var isPresented: Bool
    
    @StateObject private var viewModel = AddTransactionViewModel()
    @State private var showAddCategory = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                
                // MARK: - List
                List(viewModel.filteredCategories(isIncome: isIncome)) { category in
                    Button {
                        selectedCategory = category
                        isPresented = false
                    } label: {
                        HStack {
                            if selectedCategory?.id == category.id{
                                Text(category.name)
                                    .bold()
                            }else{
                                Text(category.name)
                            }
                            
                            Spacer()
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                   
                            }
                        }
                        .foregroundColor(Color(hex: "1D2E3E"))
                    }
                }
                .listStyle(.plain)
                .padding(.bottom, 80)
                
                // MARK: - Sticky Button
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
                        .background(Color(hex: "1D2E3E"))
                        .foregroundColor(Color(hex: "F9F9FC"))
                        .cornerRadius(14)
                    }
                }
                .padding()
                .background(
                    Color.white
                        .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
                )
            }
            .navigationTitle("Select \(isIncome ? "Income" : "Expense") Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isPresented = false } label: { Text("Close") .foregroundColor(.black) }
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView(isPresented: $showAddCategory) {
                viewModel.fetchCategories() // auto refresh
            }
        }
    }
}
