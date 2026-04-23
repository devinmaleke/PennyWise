//
//  HomeView.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var userStore = UserStore.shared
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddTransaction = false
    
    var body: some View {
        NavigationView{
            ZStack{
                AppBackgroundView()
                ScrollView {
                    VStack{
                        greetingView
                        balanceCard
                        recentTransactionHeader
                        VStack(spacing: 4){
                            ForEach(viewModel.filteredTransactions) { tx in
                                TransactionCardView(
                                    title: tx.title,
                                    category: tx.category.name,
                                    date: DateFormatter.localizedString(
                                        from: tx.date,
                                        dateStyle: .medium,
                                        timeStyle: .none
                                    ),
                                    amount: tx.category.type == .income
                                    ? "+ \(tx.amount)"
                                    : "- \(tx.amount)",
                                    isIncome: tx.category.type == .income
                                )
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 0.5)
                    }
                    .padding()
                }
                
                floatingAddButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Home")
            .sheet(isPresented: $showAddTransaction) {
                ZStack{
                    AddTransactionView(
                        isPresented: $showAddTransaction
                    ) {
                        viewModel.fetchCategoriesAndTransactions()
                    }
                }
            }
        }
        
       
    }
    
    private var greetingView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi, \(userStore.user?.name ?? "")")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "1D2E3E"))
                
                Text("Here’s your financial activity")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    private var balanceCard: some View {
        HStack{
            VStack(alignment: .leading, spacing: 8) {
                Text("This Month spend")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text(viewModel.balanceFormatted)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                
                descriptionLastMonth
            }
            
            Spacer()
        }
        .padding()
        .background(Color(hex: "1D2E3E"))
        .cornerRadius(8)
        
    }
    
    private var descriptionLastMonth: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.right")
            Text("67% below last month")
                .font(.caption2)
        }
        .foregroundColor(.white)
    }
    
    private func summaryCard(title: String, amount: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption)
            Text(amount).bold()
                .foregroundColor(color)
        }
        .cardStyle()
    }
    
    
    private var recentTransactionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .bold()
                .foregroundColor(Color(hex: "1D2E3E"))
            
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
        .padding(.vertical)
    }
    
    private var floatingAddButton: some View{
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color(hex: "1D2E3E"))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }
}

