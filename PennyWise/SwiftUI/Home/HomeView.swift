//
//  HomeView.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import SwiftUI

struct HomeView: View {

    private enum PresentedSheet: Identifiable {
        case create
        case edit(TransactionModel)
        case addAgain(QuickAddSource)

        var id: String {
            switch self {
            case .create:
                return "create"
            case .edit(let transaction):
                return "edit-\(transaction.id)"
            case .addAgain(let source):
                return source.id
            }
        }
    }

    @StateObject private var userStore = UserStore.shared
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var frequentStore = FrequentSpendStore.shared
    @State private var presentedSheet: PresentedSheet?

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 16) {
                        greetingView
                        balanceCard
                        budgetsCard
                        if showsFrequentSection {
                            FrequentSpendRow(
                                items: frequentStore.items,
                                lastAmount: lastAmount(for:),
                                onSelect: { item in
                                    presentedSheet = .addAgain(
                                        .frequent(item, lastAmount: lastAmount(for: item))
                                    )
                                },
                                onRemove: unpin
                            )
                        }
                        recentTransactionHeader

                        if viewModel.filteredTransactions.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 4) {
                                ForEach(viewModel.filteredTransactions) { tx in
                                    TransactionCardView(
                                        title: tx.title,
                                        note: tx.note,
                                        category: tx.category.name,
                                        date: tx.date.formatted(),
                                        amount: tx.amount.signedRupiah(
                                            isIncome: tx.category.type == .income
                                        ),
                                        isIncome: tx.category.type == .income,
                                        colorHex: tx.category.colorHex,
                                        showsDivider: tx.id != viewModel.filteredTransactions.last?.id,
                                        isRecurring: tx.isRecurring,
                                        onTap: {
                                            presentedSheet = .edit(tx)
                                        },
                                        onAddAgain: {
                                            presentedSheet = .addAgain(.transaction(tx))
                                        }
                                    )
                                    .contextMenu {
                                        Button {
                                            presentedSheet = .addAgain(.transaction(tx))
                                        } label: {
                                            Label("Add again", systemImage: "plus.circle")
                                        }

                                        Button {
                                            togglePin(tx)
                                        } label: {
                                            Label(
                                                isPinned(tx) ? "Unpin from Home" : "Pin to Home",
                                                systemImage: isPinned(tx) ? "star.slash" : "star"
                                            )
                                        }
                                    }
                                }
                            }
                            .background(Color.appCard)
                            .cornerRadius(8)
                            .shadow(radius: 0.5)
                        }
                    }
                    .padding()
                }

                floatingAddButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Home")
            .onAppear {
                RecurringService.generateDueIfNeeded()
                viewModel.clampSelectedMonthIfNeeded()
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .create:
                    AddTransactionView(isPresented: sheetDismissBinding) { _ in
                        viewModel.fetchCategoriesAndTransactions()
                    }
                case .edit(let transaction):
                    AddTransactionView(
                        isPresented: sheetDismissBinding,
                        transactionToEdit: transaction
                    ) { _ in
                        viewModel.fetchCategoriesAndTransactions()
                    }
                case .addAgain(let source):
                    QuickAddView(
                        isPresented: sheetDismissBinding,
                        source: source
                    ) { _ in
                        viewModel.fetchCategoriesAndTransactions()
                    }
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

    private var sheetDismissBinding: Binding<Bool> {
        Binding(
            get: { presentedSheet != nil },
            set: { if !$0 { presentedSheet = nil } }
        )
    }

    private var showsFrequentSection: Bool {
        !frequentStore.items.isEmpty || !viewModel.transactions.isEmpty
    }

    private func lastAmount(for item: FrequentSpend) -> Int {
        viewModel.transactions.first {
            FrequentSpend.fingerprint(title: $0.title, categoryId: $0.category.id)
                == FrequentSpend.fingerprint(title: item.title, categoryId: item.category.id)
        }?.amount ?? item.lastAmount
    }

    private func isPinned(_ transaction: TransactionModel) -> Bool {
        frequentStore.isPinned(title: transaction.title, categoryId: transaction.category.id)
    }

    private func togglePin(_ transaction: TransactionModel) {
        if isPinned(transaction) {
            unpinTitle(transaction.title, categoryId: transaction.category.id)
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

    private func unpin(_ item: FrequentSpend) {
        frequentStore.unpin(id: item.id) { error in
            DispatchQueue.main.async {
                if let error = error {
                    viewModel.errorMessage = AppErrorMapper.message(for: error)
                }
            }
        }
    }

    private func unpinTitle(_ title: String, categoryId: String) {
        frequentStore.unpin(title: title, categoryId: categoryId) { error in
            DispatchQueue.main.async {
                if let error = error {
                    viewModel.errorMessage = AppErrorMapper.message(for: error)
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

    private var greetingView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi, \(userStore.user?.name ?? viewModel.userName)")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color.appInk)

                Text("Here’s your financial activity")
                    .font(.footnote)
                    .foregroundColor(Color.appMuted)
            }

            Spacer()
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            monthPicker

            Text(viewModel.monthBalanceFormatted)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spent")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    Text(viewModel.monthSpendFormatted)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Income")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    Text(viewModel.monthIncomeFormatted)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                }
            }

            if let comparison = viewModel.spendComparison {
                HStack(spacing: 8) {
                    Image(systemName: comparison.systemImage)
                    Text(comparison.text)
                        .font(.caption2)
                }
                .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appAccent)
        .cornerRadius(8)
    }

    private var monthPicker: some View {
        HStack {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .disabled(!viewModel.canGoToPreviousMonth)
            .opacity(viewModel.canGoToPreviousMonth ? 1 : 0.35)
            .accessibilityLabel("Previous month")

            Spacer()

            Button {
                viewModel.goToCurrentMonth()
            } label: {
                Text(viewModel.monthTitle)
                    .font(.subheadline)
                    .bold()
            }
            .accessibilityLabel(
                viewModel.isCurrentMonth ? viewModel.monthTitle : "Show this month"
            )

            Spacer()

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .disabled(!viewModel.canGoToNextMonth)
            .opacity(viewModel.canGoToNextMonth ? 1 : 0.35)
            .accessibilityLabel("Next month")
        }
        .foregroundColor(.white)
    }

    private var budgetsCard: some View {
        Group {
            if !viewModel.budgetStatuses.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(viewModel.isCurrentMonth ? "Budgets this month" : "Budgets")
                            .bold()
                            .foregroundColor(Color.appInk)

                        Spacer()

                        if viewModel.overBudgetCount > 0 {
                            Text("\(viewModel.overBudgetCount) over")
                                .font(.caption)
                                .bold()
                                .foregroundColor(Color(hex: "E74C3C"))
                        }
                    }

                    ForEach(viewModel.budgetStatuses) { status in
                        BudgetProgressRow(
                            status: status,
                            remainingCaption: viewModel.isCurrentMonth ? "left this month" : "left"
                        )
                    }
                }
                .padding()
                .background(Color.appCard)
                .cornerRadius(8)
                .shadow(radius: 0.5)
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: viewModel.selectedFilter == .all ? "plus.circle" : "tray",
            title: emptyTitle,
            message: emptyMessage
        )
        .background(Color.appCard)
        .cornerRadius(8)
        .shadow(radius: 0.5)
    }

    private var emptyTitle: String {
        if !viewModel.isCurrentMonth {
            return "No transactions"
        }
        switch viewModel.selectedFilter {
        case .all:
            return "No transactions yet"
        case .income:
            return "No income yet"
        case .expense:
            return "No expenses yet"
        }
    }

    private var emptyMessage: String {
        if !viewModel.isCurrentMonth {
            return "Nothing recorded in \(viewModel.monthTitle)"
        }
        switch viewModel.selectedFilter {
        case .all:
            return "Tap + to add your first income or expense"
        case .income:
            return "Add a salary or other income to see it here"
        case .expense:
            return "Add a purchase to start tracking spend"
        }
    }

    private var recentTransactionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .bold()
                .foregroundColor(Color.appInk)

            Picker(
                "Filter",
                selection: $viewModel.selectedFilter
            ) {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    presentedSheet = .create
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.appAccent)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }
}
