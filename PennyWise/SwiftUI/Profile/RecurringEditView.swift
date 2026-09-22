//
//  RecurringEditView.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import SwiftUI

struct RecurringEditView: View {

    @Binding var isPresented: Bool
    let template: RecurringTemplate

    @State private var title = ""
    @State private var note = ""
    @State private var amount = ""
    @State private var frequency: RecurringFrequency = .monthly
    @State private var selectedOption: Options = .expense
    @State private var showCategoryPicker = false
    @State private var selectedCategory: CategoryModel?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didPrefill = false

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
            VStack(spacing: 20) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        CustomSegmentedControl(selectedOption: $selectedOption)
                            .onChange(of: selectedOption) { newValue in
                                if selectedCategory?.type != newValue.transactionType {
                                    selectedCategory = nil
                                }
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
                                    Text(selectedCategory?.name ?? "Select Category")
                                        .foregroundColor(
                                            selectedCategory == nil ? Color.appMuted : Color.appInk
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
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Repeat")
                                .bold()
                                .foregroundColor(Color.appInk)

                            Picker("Repeat", selection: $frequency) {
                                ForEach(RecurringFrequency.allCases) { item in
                                    Text(item.title).tag(item)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }

                Button {
                    save()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.appOnAccent))
                        }
                        Text("Save Changes")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appAccent)
                    .foregroundColor(Color.appOnAccent)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isSaving)
                .opacity(isFormValid && !isSaving ? 1 : 0.5)
            }
            .padding()
            }
            .navigationTitle("Edit Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isPresented = false } label: { Text("Close").foregroundColor(Color.appInk) }
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
            .onAppear {
                prefillIfNeeded()
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerView(
                isIncome: selectedOption == .income,
                selectedCategory: $selectedCategory,
                isPresented: $showCategoryPicker
            )
        }
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (AmountParser.parse(amount) ?? 0) > 0
            && selectedCategory != nil
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func prefillIfNeeded() {
        guard !didPrefill else { return }
        didPrefill = true
        title = template.title
        note = template.note
        amount = AmountParser.grouped(template.amount)
        frequency = template.frequency
        selectedOption = template.isIncome ? .income : .expense
        selectedCategory = template.category
    }

    private func save() {
        guard let category = selectedCategory else { return }
        isSaving = true

        let updated = RecurringTemplate(
            id: template.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: AmountParser.parse(amount) ?? 0,
            category: category,
            isIncome: category.type == .income,
            frequency: frequency,
            nextDate: template.nextDate,
            isActive: template.isActive
        )

        RecurringService.update(updated) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .failure(let error):
                    errorMessage = AppErrorMapper.message(for: error)
                case .success:
                    isPresented = false
                }
            }
        }
    }
}
