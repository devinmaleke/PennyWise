//
//  AddTransactionView.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import SwiftUI

struct AddTransactionView: View {

    @Binding var isPresented: Bool
    var transactionToEdit: TransactionModel? = nil
    var onCompleted: (TransactionFormResult) -> Void = { _ in }

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var amount: String = ""
    @State private var selectedOption: Options = .expense
    @State private var date: Date = Date()
    @State private var showCategoryPicker = false
    @State private var showDeleteConfirm = false
    @State private var isRecurring = false
    @State private var frequency: RecurringFrequency = .monthly

    @StateObject private var viewModel = AddTransactionViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                    CustomSegmentedControl(selectedOption: $selectedOption)
                        .onChange(of: selectedOption) { newValue in
                            viewModel.resetCategoryIfNeeded(
                                isIncome: newValue == .income
                            )
                        }

                    inputField(title: "Title", text: $title)

                    inputField(title: "Note (optional)", text: $note)

                    AmountInputField(text: $amount)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category")
                            .bold()
                            .foregroundColor(Color.appInk)

                        Button {
                            showCategoryPicker = true
                        } label: {
                            HStack {
                                Text(viewModel.selectedCategory?.name ?? "Select Category")
                                    .foregroundColor(
                                        viewModel.selectedCategory == nil ? Color.appMuted : Color.appInk
                                    )

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.appMuted)
                            }
                            .padding()
                            .background(Color.appFill)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.appDivider)
                            )
                            .padding(.horizontal,2)
                        }
                    }

                    CustomDateField(
                        title: "Date",
                        date: $date,
                        textColor: Color.appInk,
                        labelColor: Color.appInk
                    )

                    if transactionToEdit == nil {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $isRecurring) {
                                Text("Repeat")
                                    .bold()
                                    .foregroundColor(Color.appInk)
                            }

                            if isRecurring {
                                Picker("Repeat", selection: $frequency) {
                                    ForEach(RecurringFrequency.allCases) { item in
                                        Text(item.title).tag(item)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())

                                Text("The next one is added automatically when it’s due.")
                                    .font(.caption)
                                    .foregroundColor(Color.appMuted)
                            }
                        }
                        .padding(.horizontal,2)
                    }
                        }
                    }

                    Spacer(minLength: 0)

                    Button {
                        save()
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.appOnAccent))
                            }
                            Text(transactionToEdit == nil ? "Save Transaction" : "Save Changes")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appAccent)
                        .foregroundColor(Color.appOnAccent)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                    .opacity(isFormValid && !viewModel.isLoading ? 1 : 0.5)

                    if transactionToEdit != nil {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete Transaction")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding()
                .navigationTitle(transactionToEdit == nil ? "Add Transaction" : "Edit Transaction")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button(action: {
                        isPresented = false
                    }, label: {
                        Text("Close")
                            .foregroundColor(Color.appInk)
                    })
                )
                .alert(isPresented: errorAlertBinding) {
                    Alert(
                        title: Text("Error"),
                        message: Text(viewModel.errorMessage ?? AppErrorMapper.genericMessage),
                        dismissButton: .default(Text("OK")) {
                            viewModel.errorMessage = nil
                        }
                    )
                }
                .confirmationDialog(
                    "Delete Transaction",
                    isPresented: $showDeleteConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        delete()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This cannot be undone.")
                }
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerView(
                isIncome: selectedOption == .income,
                selectedCategory: $viewModel.selectedCategory,
                isPresented: $showCategoryPicker
            )
        }
        .onAppear {
            prefillIfNeeded()
        }
    }
}

// MARK: - Helpers
private extension AddTransactionView {

    var isFormValid: Bool {
        let parsedAmount = AmountParser.parse(amount)
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (parsedAmount ?? 0) > 0 &&
            viewModel.selectedCategory != nil
    }

    var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    func prefillIfNeeded() {
        guard let transaction = transactionToEdit else { return }

        title = transaction.title
        note = transaction.note
        amount = AmountParser.grouped(transaction.amount)
        date = transaction.date
        selectedOption = transaction.category.type == .income ? .income : .expense
        viewModel.beginEditing(transaction)
    }

    func save() {
        viewModel.saveTransaction(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: AmountParser.parse(amount) ?? 0,
            date: date,
            isIncome: selectedOption == .income,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            frequency: transactionToEdit == nil && isRecurring ? frequency : nil
        ) { transaction in
            isPresented = false
            onCompleted(.saved(transaction))
        }
    }

    func delete() {
        guard let transactionId = transactionToEdit?.id else { return }

        viewModel.deleteTransaction {
            isPresented = false
            onCompleted(.deleted(transactionId))
        }
    }
}


struct CustomDateField: View {

    let title: String
    @Binding var date: Date
    var textColor: Color = Color.appInk
    var labelColor: Color = Color.appInk

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
                .background(Color.appFill)
                .cornerRadius(8)
                .shadow(radius: 1)
            }
        }
        .padding(.horizontal,2)
        .sheet(isPresented: $showPicker) {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .accentColor(Color.appInk)
            }
        }
    }
}
