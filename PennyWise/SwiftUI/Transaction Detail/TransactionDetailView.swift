//
//  TransactionDetailView.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/01/26.
//

import SwiftUI

struct TransactionDetailView: View {

    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: TransactionDetailViewModel
    @ObservedObject private var frequentStore = FrequentSpendStore.shared
    @State private var presentedSheet: PresentedSheet?

    private enum PresentedSheet: Identifiable {
        case edit(TransactionModel)
        case addAgain(QuickAddSource)

        var id: String {
            switch self {
            case .edit(let transaction):
                return "edit-\(transaction.id)"
            case .addAgain(let source):
                return source.id
            }
        }
    }

    init(
        category: CategoryModel,
        transactions: [TransactionModel],
        startDate: Date? = nil,
        endDate: Date? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: TransactionDetailViewModel(
                category: category,
                transactions: transactions,
                startDate: startDate,
                endDate: endDate
            )
        )
    }

    var body: some View {
        ZStack {
            AppBackgroundView()
            VStack(spacing: 0) {
                summaryHeader
                SearchField(
                    text: $viewModel.searchText,
                    placeholder: "Search title or note"
                )
                .padding(.horizontal)
                .padding(.bottom, 8)

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
                        .foregroundColor(Color.appInk)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(viewModel.category.name)
                    .foregroundColor(Color.appInk)
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
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .edit(let transaction):
                AddTransactionView(
                    isPresented: sheetDismissBinding,
                    transactionToEdit: transaction,
                    onCompleted: { result in
                        viewModel.apply(result)
                    }
                )
            case .addAgain(let source):
                QuickAddView(
                    isPresented: sheetDismissBinding,
                    source: source,
                    onCompleted: { result in
                        viewModel.apply(result)
                    }
                )
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: 8) {
            Text(viewModel.formattedTotal)
                .font(.title)
                .bold()
                .foregroundColor(Color.appInk)

            if let status = viewModel.thisMonthBudgetStatus {
                BudgetProgressRow(status: status, showsCategoryName: false)
                    .padding(.horizontal)
            }
            
            HStack {
                Text(viewModel.dateRangeLabel)
                    .font(.caption)
                    .foregroundColor(Color.appMuted)

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
                    .foregroundColor(Color.appInk)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 12)
    }

    private var sheetDismissBinding: Binding<Bool> {
        Binding(
            get: { presentedSheet != nil },
            set: { if !$0 { presentedSheet = nil } }
        )
    }

    private func isPinned(_ transaction: TransactionModel) -> Bool {
        frequentStore.isPinned(title: transaction.title, categoryId: transaction.category.id)
    }

    private func togglePin(_ transaction: TransactionModel) {
        if isPinned(transaction) {
            frequentStore.unpin(
                title: transaction.title,
                categoryId: transaction.category.id
            ) { _ in }
            return
        }

        frequentStore.pin(
            title: transaction.title,
            note: transaction.note,
            lastAmount: transaction.amount,
            category: transaction.category
        ) { _ in }
    }

    // MARK: - Transaction List (grouped by date)

    private var transactionList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.groupedByDate, id: \.key) { group in
                VStack(alignment: .leading, spacing: 0) {

                    // Section date header
                    Text(group.key)
                        .font(.caption)
                        .foregroundColor(Color.appMuted)
                        .padding(.horizontal)
                        .padding(.bottom, 6)

                    // Cards
                    VStack(spacing: 0) {
                        ForEach(group.value) { transaction in
                            TransactionDetailList(
                                title: transaction.title,
                                note: transaction.note,
                                date: transaction.date.formatted(),
                                amount: transaction.amount.asRupiah,
                                isIncome: transaction.category.type == .income,
                                colorHex: transaction.category.colorHex,
                                showsDivider: transaction.id != group.value.last?.id,
                                isRecurring: transaction.isRecurring,
                                onTap: {
                                    presentedSheet = .edit(transaction)
                                },
                                onAddAgain: {
                                    presentedSheet = .addAgain(.transaction(transaction))
                                }
                            )
                            .contextMenu {
                                Button {
                                    presentedSheet = .addAgain(.transaction(transaction))
                                } label: {
                                    Label("Add again", systemImage: "plus.circle")
                                }

                                Button {
                                    togglePin(transaction)
                                } label: {
                                    Label(
                                        isPinned(transaction) ? "Unpin from Home" : "Pin to Home",
                                        systemImage: isPinned(transaction) ? "star.slash" : "star"
                                    )
                                }
                            }
                        }
                    }
                    .background(Color.appCard)
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
        EmptyStateView(
            icon: viewModel.isSearching ? "magnifyingglass" : "calendar",
            title: viewModel.isSearching ? "No matches" : "Nothing in this date range",
            message: viewModel.isSearching
                ? "Try a different title or note"
                : "Choose a wider range to see transactions"
        )
    }
}
