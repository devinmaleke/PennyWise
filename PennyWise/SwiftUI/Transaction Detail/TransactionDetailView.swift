//
//  TransactionDetailView.swift
//  PennyWise
//
//  Created by Samir iOS on 21/01/26.
//

import SwiftUI

struct TransactionDetailView: View {

    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: TransactionDetailViewModel

    init(category: CategoryModel, transactions: [TransactionModel]) {
        _viewModel = StateObject(
            wrappedValue: TransactionDetailViewModel(
                category: category,
                transactions: transactions
            )
        )
    }

    var body: some View {
        ZStack {
            AppBackgroundView()
            VStack(spacing: 0) {
                summaryHeader
                ScrollView {
                    if viewModel.filteredTransactions.isEmpty {
                        emptyState
                    } else {
                        transactionList
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(hex: "1D2E3E"))
                }
            }
            ToolbarItem(placement: .principal) {
                Text(viewModel.category.name)
                    .foregroundColor(Color(hex: "1D2E3E"))
                    .bold()
            }
        }
        .sheet(isPresented: $viewModel.showDatePicker) {
            DateRangeButtonPickerView(
                startDate: $viewModel.startDate,
                endDate: $viewModel.endDate,
                onApply: {
                    viewModel.showDatePicker = false
                }
            )
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: 8) {
            Text(viewModel.formattedTotal)
                .font(.title)
                .bold()
                .foregroundColor(Color(hex: "1D2E3E"))
            
            HStack {
                Text(viewModel.dateRangeLabel)
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Button {
                    viewModel.showDatePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Choose Date")
                            .font(.subheadline)
                        Image(systemName: "calendar.circle.fill")
                            .imageScale(.medium)
                    }
                    .foregroundColor(Color(hex: "1D2E3E"))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 12)
    }

    // MARK: - Transaction List (grouped by date)

    private var transactionList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.groupedByDate, id: \.key) { group in
                VStack(alignment: .leading, spacing: 0) {

                    // Section date header
                    Text(group.key)
                        .font(.caption)
                        .foregroundColor(Color(hex: "466C85"))
                        .padding(.horizontal)
                        .padding(.bottom, 6)

                    // Cards
                    VStack(spacing: 0) {
                        ForEach(group.value) { transaction in
                            TransactionDetailList(
                                title: transaction.title,
                                date: transaction.date.formatted(),
                                amount: formattedAmount(transaction.amount),
                                isIncome: transaction.category.type == .income
                            )
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 0.5)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "466C85"))
            Text("No transactions in this range")
                .font(.caption)
                .foregroundColor(Color(hex: "466C85"))
        }
        .padding(.top, 60)
    }

    // MARK: - Helper

    private func formattedAmount(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
