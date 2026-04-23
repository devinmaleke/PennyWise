//
//  AddTransactionView.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import SwiftUI

struct AddTransactionView: View {

    @Binding var isPresented: Bool
    var onSave: () -> Void

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var selectedOption: Options = .expense
    @State private var date: Date = Date()

    @State private var showCategoryPicker = false

    @StateObject private var viewModel = AddTransactionViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 20) {

                    CustomSegmentedControl(selectedOption: $selectedOption)
                        .onChange(of: selectedOption) { newValue in
                            viewModel.resetCategoryIfNeeded(
                                isIncome: newValue == .income
                            )
                        }

                    inputField(title: "Title", text: $title)

                    inputField(
                        title: "Amount",
                        text: $amount,
                        keyboard: .numberPad
                    )

                    // Category
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category")
                            .bold()
                            .foregroundColor(Color(hex: "1D2E3E"))

                        Button {
                            showCategoryPicker = true
                        } label: {
                            HStack {
                                Text(viewModel.selectedCategory?.name ?? "Select Category")
                                    .foregroundColor(
                                        viewModel.selectedCategory == nil ? Color(.systemGray4) : .black
                                    )

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color(.systemGray4))
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3))
                            )
                        }
                    }

                    CustomDateField(
                        title: "Date",
                        date: $date,
                        textColor: .black,
                        labelColor: Color(hex: "1D2E3E")
                    )

                    Spacer()

                    Button {
                        save()
                    } label: {
                        Text("Save Transaction")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "1D2E3E"))
                            .foregroundColor(Color(hex: "F9F9FC"))
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1 : 0.5)
                }
                .padding()
                .navigationTitle("Add Transaction")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button(action: {
                        isPresented = false
                    }, label: {
                        Text("Close")
                            .foregroundColor(.black)
                    })
                )
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerView(
                isIncome: selectedOption == .income,
                selectedCategory: $viewModel.selectedCategory,
                isPresented: $showCategoryPicker
            )
        }
    }
}

// MARK: - Helpers
private extension AddTransactionView {

    var isFormValid: Bool {
        !title.isEmpty &&
        Int(amount) != nil &&
        viewModel.selectedCategory != nil
    }

    func save() {
        viewModel.saveTransaction(
            title: title,
            amount: Int(amount) ?? 0,
            date: date,
            isIncome: selectedOption == .income
        ) {
            isPresented = false
            onSave()
        }
    }
}


struct CustomDateField: View {

    let title: String
    @Binding var date: Date
    var textColor: Color = .blue
    var labelColor: Color = .red

    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text(title)
                .foregroundColor(labelColor)
                .bold()

            Button {
                showPicker = true
            } label: {
                HStack {
                    Text(date.formatted())
                        .foregroundColor(textColor)

                    Spacer()

                    Image(systemName: "calendar")
                        .foregroundColor(textColor)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 1)
            }
        }
        .sheet(isPresented: $showPicker) {
            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
        }
    }
}
