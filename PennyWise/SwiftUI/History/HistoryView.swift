//
//  HistoryView.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import SwiftUI

struct HistoryView: View {

    @StateObject private var viewModel = HistoryViewModel()
    @ObservedObject private var frequentStore = FrequentSpendStore.shared
    @State private var goToDetail = false
    @State private var selectedCategory: CategoryModel? = nil
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

    @State private var presentedSheet: PresentedSheet?

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
                VStack(spacing: 16) {
                    header
                    SearchField(
                        text: $viewModel.searchText,
                        placeholder: "Search title, category, or note"
                    )
                    ScrollView {
                        segmentedPicker
                        recentTransactionHeader
                        results
                    }
                    Spacer()
                }
                .padding()

                NavigationLink(
                    destination: Group {
                        if let category = selectedCategory {
                            TransactionDetailView(
                                category: category,
                                transactions: viewModel.transactions(for: category),
                                startDate: viewModel.detailStartDate,
                                endDate: viewModel.detailEndDate
                            )
                        }
                    },
                    isActive: $goToDetail
                ) {
                    EmptyView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .edit(let transaction):
                    AddTransactionView(
                        isPresented: sheetDismissBinding,
                        transactionToEdit: transaction
                    )
                case .addAgain(let source):
                    QuickAddView(
                        isPresented: sheetDismissBinding,
                        source: source
                    )
                }
            }
            .alert(isPresented: errorAlertBinding) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? AppErrorMapper.genericMessage),
                    dismissButton: .default(Text("OK")) {
                        viewModel.errorMessage = nil
                    }
                )
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Transactions")
                .bold()
                .foregroundColor(Color.appInk)
        }
        .padding(.bottom, 4)
    }

    private var segmentedPicker: some View {
        CustomSegmentedControl(
            selectedOption: Binding(
                get: {
                    viewModel.selectedType == .income ? .income : .expense
                },
                set: { newValue in
                    viewModel.selectedType =
                    newValue == .income ? .income : .expense
                }
            )
        )
    }

    private var recentTransactionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                (viewModel.selectedType == .income
                 ? Text("Total Income")
                 : Text("Total Expense"))
                .bold()
                .foregroundColor(Color.appInk)

                Text(viewModel.totalAmountFormatted)
                    .font(.title3)
                    .bold()
                    .foregroundColor(Color.appInk)
            }

            Spacer()

            Menu {
                ForEach(FilterPeriod.allCases, id: \.self) { period in
                    Button {
                        viewModel.selectedPeriod = period
                    } label: {
                        HStack {
                            Text(period.rawValue)
                            if viewModel.selectedPeriod == period {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.selectedPeriod.rawValue)
                        .font(.subheadline)
                        .foregroundColor(Color.appInk)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color.appMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.appFill)
                .cornerRadius(8)
            }
        }
        .padding(.vertical)
    }

    private var results: some View {
        VStack(spacing: 16) {
            if viewModel.filteredTransactions.isEmpty {
                emptyState
            } else if viewModel.isSearching {
                searchResults
            } else {
                categoryList
            }
        }
        .padding(.horizontal,2)
    }

    private var categoryList: some View {
        VStack {
            ForEach(viewModel.groupedByCategory, id: \.category.id) { item in
                CategoryCardView(
                    icon: "circle.fill",
                    title: item.category.name,
                    totalSpend: item.total,
                    color: Color(hex: item.category.colorHex),
                    budgetStatus: viewModel.showsMonthlyBudget
                        ? CategoryBudgetStatus.from(category: item.category, spent: item.total)
                        : nil
                ) {
                    selectedCategory = item.category
                    goToDetail = true
                }
            }
            .padding(.vertical)
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(8)
        .shadow(radius: 0.5)
    }

    private var searchResults: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.groupedTransactions, id: \.key) { group in
                VStack(alignment: .leading, spacing: 0) {
                    Text(group.key)
                        .font(.caption)
                        .foregroundColor(Color.appMuted)
                        .padding(.bottom, 6)

                    VStack(spacing: 0) {
                        ForEach(group.value) { transaction in
                            TransactionCardView(
                                title: transaction.title,
                                note: transaction.note,
                                category: transaction.category.name,
                                date: transaction.date.formatted(),
                                amount: transaction.amount.signedRupiah(
                                    isIncome: transaction.category.type == .income
                                ),
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
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: viewModel.isSearching ? "magnifyingglass" : "tray",
            title: viewModel.isSearching ? "No matches" : emptyTitle,
            message: viewModel.isSearching
                ? "Try a different title, category, or note"
                : "Add a transaction or pick a different date range"
        )
    }

    private var emptyTitle: String {
        viewModel.selectedType == .income
            ? "No income this period"
            : "No expenses this period"
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
            ) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        viewModel.errorMessage = AppErrorMapper.message(for: error)
                    }
                }
            }
            return
        }

        frequentStore.pin(
            title: transaction.title,
            note: transaction.note,
            lastAmount: transaction.amount,
            category: transaction.category
        ) { error in
            DispatchQueue.main.async {
                if let error = error {
                    viewModel.errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? AppErrorMapper.message(for: error)
                }
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}
