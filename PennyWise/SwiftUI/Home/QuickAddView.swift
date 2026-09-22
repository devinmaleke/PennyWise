//
//  QuickAddView.swift
//  PennyWise
//
//  Created by Devin Maleke on 22/09/26.
//

import SwiftUI

struct QuickAddView: View {

    @Binding var isPresented: Bool
    let source: QuickAddSource
    var onCompleted: (TransactionFormResult) -> Void = { _ in }

    @State private var amount = ""
    @State private var pinError: String?
    @StateObject private var viewModel = AddTransactionViewModel()
    @ObservedObject private var frequentStore = FrequentSpendStore.shared

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
                VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: source.category.colorHex))
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.title)
                            .font(.title3)
                            .bold()
                            .foregroundColor(Color.appInk)

                        Text(source.category.name)
                            .font(.subheadline)
                            .foregroundColor(Color.appMuted)
                    }
                }

                AmountInputField(title: "Today’s amount", autofocus: true, text: $amount)

                if source.lastAmount > 0 {
                    Button {
                        amount = AmountParser.grouped(source.lastAmount)
                    } label: {
                        Text("Last time: \(source.lastAmount.asRupiah) · Use this")
                            .font(.caption)
                            .foregroundColor(Color.appMuted)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button {
                    togglePin()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPinned ? "star.fill" : "star")
                        Text(isPinned ? "Pinned to Home" : "Pin to Home")
                            .bold()
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.appInk)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(isPinned ? "Unpin from Home" : "Pin to Home")

                Spacer()

                Button {
                    save()
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.appOnAccent))
                        }
                        Text("Save for today")
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
            }
            .padding()
            }
            .navigationTitle("Add again")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isPresented = false } label: {
                        Text("Close").foregroundColor(Color.appInk)
                    }
                }
            }
            .alert(isPresented: errorAlertBinding) {
                Alert(
                    title: Text("Error"),
                    message: Text(activeErrorMessage),
                    dismissButton: .default(Text("OK")) {
                        viewModel.errorMessage = nil
                        pinError = nil
                    }
                )
            }
            .onAppear {
                viewModel.beginRepeat(category: source.category)
            }
        }
    }

    private var isPinned: Bool {
        frequentStore.isPinned(title: source.title, categoryId: source.category.id)
    }

    private var isFormValid: Bool {
        (AmountParser.parse(amount) ?? 0) > 0 && viewModel.selectedCategory != nil
    }

    private var activeErrorMessage: String {
        pinError ?? viewModel.errorMessage ?? AppErrorMapper.genericMessage
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil || pinError != nil },
            set: { if !$0 {
                viewModel.errorMessage = nil
                pinError = nil
            } }
        )
    }

    private func togglePin() {
        if isPinned {
            frequentStore.unpin(title: source.title, categoryId: source.category.id) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        pinError = AppErrorMapper.message(for: error)
                    }
                }
            }
            return
        }

        frequentStore.pin(
            title: source.title,
            note: source.note,
            lastAmount: AmountParser.parse(amount) ?? source.lastAmount,
            category: source.category
        ) { error in
            DispatchQueue.main.async {
                if let error = error {
                    pinError = (error as? LocalizedError)?.errorDescription
                        ?? AppErrorMapper.message(for: error)
                }
            }
        }
    }

    private func save() {
        let parsedAmount = AmountParser.parse(amount) ?? 0
        viewModel.saveTransaction(
            title: source.title,
            amount: parsedAmount,
            date: Date(),
            isIncome: source.category.type == .income,
            note: source.note
        ) { transaction in
            frequentStore.recordUse(
                title: transaction.title,
                categoryId: transaction.category.id,
                amount: parsedAmount
            )
            isPresented = false
            onCompleted(.saved(transaction))
        }
    }
}
