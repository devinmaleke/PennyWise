//
//  SummaryShareCard.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import SwiftUI

struct SummaryShareCard: View {

    let period: String
    let net: Int
    let income: Int
    let spend: Int
    let expenses: [CategorySlice]
    let incomeSlices: [CategorySlice]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PennyWise")
                    .font(.headline)
                    .bold()
                    .foregroundColor(Color(hex: "1D2E3E"))
                Spacer()
                Text(period)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "466C85"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Net")
                    .font(.caption)
                    .foregroundColor(Color(hex: "466C85"))
                Text(net.asRupiah)
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "1D2E3E"))
            }

            HStack {
                shareMetric(title: "Income", value: income.asRupiah, color: Color(hex: "27AE60"))
                Spacer()
                shareMetric(title: "Spent", value: spend.asRupiah, color: Color(hex: "E74C3C"))
            }

            ComparisonBar(
                incomeShare: share(income),
                spendShare: share(spend)
            )

            if !expenses.isEmpty {
                categoryBlock(title: "Top expenses", slices: expenses)
            }

            if !incomeSlices.isEmpty {
                categoryBlock(title: "Top income", slices: incomeSlices)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "EFF3F6"), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func share(_ value: Int) -> Double {
        let total = income + spend
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }

    private func shareMetric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(Color(hex: "466C85"))
            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
        }
    }

    private func categoryBlock(title: String, slices: [CategorySlice]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundColor(Color(hex: "1D2E3E"))

            ForEach(slices) { slice in
                HStack {
                    Circle()
                        .fill(Color(hex: slice.colorHex))
                        .frame(width: 8, height: 8)
                    Text(slice.name)
                        .font(.caption)
                        .foregroundColor(Color(hex: "1D2E3E"))
                    Spacer()
                    Text(slice.amount.asRupiah)
                        .font(.caption)
                        .bold()
                        .foregroundColor(Color(hex: "1D2E3E"))
                }
            }
        }
    }
}
