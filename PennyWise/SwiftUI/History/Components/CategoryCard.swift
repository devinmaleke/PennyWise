//
//  CategoryCard.swift
//  PennyWise
//
//  Created by Devin Maleke on 20/01/26.
//

import SwiftUI

struct CategoryCardView: View {
    let icon: String
    let title: String
    let totalSpend: Int
    let color: Color
    var budgetStatus: CategoryBudgetStatus? = nil
    var onTapDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {

                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 20, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appInk)

                    Text(totalSpend.asRupiah)
                        .font(.system(size: 14))
                        .foregroundColor(Color.appMuted)
                }

                Spacer()

                Button(action: onTapDetail) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.appMuted)
                }
            }

            if let budgetStatus = budgetStatus {
                BudgetProgressRow(status: budgetStatus, showsCategoryName: false)
            }
        }
    }
}
