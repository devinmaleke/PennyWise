//
//  SummaryView.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import SwiftUI

struct SummaryView: View {

    @StateObject private var viewModel = SummaryViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        periodMenu
                        overviewCard
                        comparisonCard
                        breakdownCard
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
            Text("Summary")
                .bold()
                .foregroundColor(Color.appInk)

            Spacer()

            Button {
                shareSummary()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color.appInk)
                    .padding(8)
                    .background(Color.appFill)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Share summary")
        }
    }

    private var periodMenu: some View {
        HStack {
            Text("Overview")
                .font(.subheadline)
                .foregroundColor(Color.appMuted)
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
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Net")
                .font(.caption)
                .foregroundColor(Color.appMuted)
            Text(viewModel.netTotal.asRupiah)
                .font(.title)
                .bold()
                .foregroundColor(Color.appInk)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Income")
                        .font(.caption2)
                        .foregroundColor(Color.appMuted)
                    Text(viewModel.incomeTotal.asRupiah)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Color(hex: "27AE60"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Spent")
                        .font(.caption2)
                        .foregroundColor(Color.appMuted)
                    Text(viewModel.spendTotal.asRupiah)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Color(hex: "E74C3C"))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appCard)
        .cornerRadius(8)
        .shadow(radius: 0.5)
    }

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income vs spend")
                .bold()
                .foregroundColor(Color.appInk)

            ComparisonBar(
                incomeShare: viewModel.incomeShare,
                spendShare: viewModel.spendShare
            )

            HStack {
                legendDot(color: Color(hex: "27AE60"), title: "Income")
                Spacer()
                legendDot(color: Color(hex: "E74C3C"), title: "Spend")
            }
            .font(.caption)
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(8)
        .shadow(radius: 0.5)
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By category")
                .bold()
                .foregroundColor(Color.appInk)

            CustomSegmentedControl(
                selectedOption: Binding(
                    get: { viewModel.selectedType == .income ? .income : .expense },
                    set: { viewModel.selectedType = $0.transactionType }
                )
            )

            if viewModel.slices.isEmpty {
                emptyState
            } else {
                HStack {
                    Spacer()
                    DonutChart(slices: viewModel.slices)
                        .frame(width: 160, height: 160)
                        .overlay(
                            VStack(spacing: 2) {
                                Text(viewModel.selectedType == .income ? "Income" : "Spend")
                                    .font(.caption2)
                                    .foregroundColor(Color.appMuted)
                                Text(viewModel.breakdownTotal.asRupiah)
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(Color.appInk)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.7)
                                    .padding(.horizontal, 20)
                            }
                        )
                    Spacer()
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.slices) { slice in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: slice.colorHex))
                                    .frame(width: 10, height: 10)

                                Text(slice.name)
                                    .foregroundColor(Color.appInk)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(slice.amount.asRupiah)
                                        .bold()
                                        .foregroundColor(Color.appInk)
                                    Text("\(Int((slice.percent * 100).rounded()))%")
                                        .font(.caption2)
                                        .foregroundColor(Color.appMuted)
                                }
                            }

                            if let status = viewModel.budgetStatus(for: slice) {
                                BudgetProgressRow(status: status, showsCategoryName: false)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(8)
        .shadow(radius: 0.5)
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "chart.pie",
            title: "No data for this period",
            message: "Add transactions or pick another range"
        )
        .padding(.vertical, 8)
    }

    private func shareSummary() {
        let expenses = Array(viewModel.slices(for: .expense).prefix(5))
        let income = Array(viewModel.slices(for: .income).prefix(5))
        let card = SummaryShareCard(
            period: viewModel.selectedPeriod.rawValue,
            net: viewModel.netTotal,
            income: viewModel.incomeTotal,
            spend: viewModel.spendTotal,
            expenses: expenses,
            incomeSlices: income
        )

        var height: CGFloat = 260
        if !expenses.isEmpty {
            height += 36 + CGFloat(expenses.count) * 24
        }
        if !income.isEmpty {
            height += 36 + CGFloat(income.count) * 24
        }

        var items: [Any] = [viewModel.shareText]
        if let image = SharePresenter.image(from: card, size: CGSize(width: 360, height: height)) {
            items.insert(image, at: 0)
        }
        SharePresenter.present(items: items)
    }

    private func legendDot(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundColor(Color.appMuted)
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
