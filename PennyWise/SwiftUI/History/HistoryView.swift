//
//  HistoryView.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import SwiftUI

struct HistoryView: View {
    
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedOption: Options = .expense
    @State private var goToDetail = false
    @State private var selectedCategory: CategoryModel? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
                VStack(spacing: 16) {
                    header
                    ScrollView {
                        segmentedPicker
                        recentTransactionHeader
                        categoriesSpend
                    }
                    Spacer()
                }
                .padding()
                
                NavigationLink(
                    destination: Group {
                        if let category = selectedCategory {
                            TransactionDetailView(
                                category: category,
                                transactions: viewModel.transactions(for: category)
                            )
                        }
                    },
                    isActive: $goToDetail
                ) {
                    EmptyView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    
    private var header: some View {
        HStack {
            Text("Transactions")
                .bold()
                .foregroundColor(Color(hex: "1D2E3E"))
        }
        .padding(.bottom, 16)
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
            (viewModel.selectedType == .income
             ? Text("Total Income")
             : Text("Total Expense"))
            .bold()
            .foregroundColor(Color(hex: "1D2E3E"))
            
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
                        .foregroundColor(Color(hex: "1D2E3E"))
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color(hex: "466C85"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "EFF3F6"))
                .cornerRadius(8)
            }
        }
        .padding(.vertical)
    }
    
    private var categoriesSpend: some View {
            VStack(spacing: 16) {
                if viewModel.filteredTransactions.isEmpty {
                    emptyState
                } else {
                    VStack {
                        ForEach(viewModel.groupedByCategory, id: \.category.id) { item in
                            CategoryCardView(
                                icon: "circle.fill",
                                title: item.category.name,
                                totalSpend: Double(item.total),
                                color: item.category.type == .income ? .green : .red
                            ) {
                                selectedCategory = item.category  // ← set category
                                goToDetail = true
                            }
                        }
                        .padding(.vertical)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 0.5)
                }
            }
        }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "466C85"))
            
            Text("No transactions")
                .font(.caption)
                .foregroundColor(Color(hex: "466C85"))
        }
        .padding(.top, 40)
    }
    
    
}
