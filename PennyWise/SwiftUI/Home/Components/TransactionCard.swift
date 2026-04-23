//
//  TransactionCard.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import SwiftUI

struct TransactionCardView: View {

    let title: String
    let category: String
    let date: String
    let amount: String
    let isIncome: Bool

    var body: some View {
        VStack{
            HStack(spacing: 12) {
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .bold()
                        .foregroundColor(Color(hex: "1D2E3E"))
                    
                    Text(category)
                        .font(.caption)
                        .foregroundColor(Color(hex: "466C85"))
                    
                    Text(date)
                        .font(.caption2)
                        .foregroundColor(Color(hex: "466C85"))
                }
                
                Spacer()
                
                Text(amount)
                    .font(.body)
                    .bold()
                    .foregroundColor(isIncome ? .green : .red)
                
            }
            .padding()
            CustomDivider()
                .padding(.horizontal)
        }
    }
}
