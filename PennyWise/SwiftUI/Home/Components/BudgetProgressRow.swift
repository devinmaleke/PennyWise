//
//  BudgetProgressRow.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import SwiftUI

struct BudgetProgressRow: View {

    let status: CategoryBudgetStatus
    var showsCategoryName: Bool = true
    var remainingCaption: String = "left this month"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if showsCategoryName {
                    Circle()
                        .fill(Color(hex: status.colorHex))
                        .frame(width: 8, height: 8)

                    Text(status.name)
                        .font(.subheadline)
                        .foregroundColor(Color.appInk)
                }

                Spacer()

                Text("\(status.spent.asRupiah) / \(status.budget.asRupiah)")
                    .font(.caption)
                    .bold()
                    .foregroundColor(Color.appInk)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appFill)

                    Capsule()
                        .fill(status.isOver ? Color(hex: "E74C3C") : Color(hex: status.colorHex))
                        .frame(width: max(6, geometry.size.width * CGFloat(status.progress)))
                }
            }
            .frame(height: 8)

            Text(status.isOver
                 ? "Over by \(status.overAmount.asRupiah)"
                 : "\(status.remaining.asRupiah) \(remainingCaption)")
                .font(.caption2)
                .foregroundColor(status.isOver ? Color(hex: "E74C3C") : Color.appMuted)
        }
    }
}
