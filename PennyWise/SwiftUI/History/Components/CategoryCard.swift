//
//  CategoryCard.swift
//  PennyWise
//
//  Created by Samir iOS on 20/01/26.
//

import SwiftUI

struct CategoryCardView: View {
    let icon: String
    let title: String
    let totalSpend: Double
    let color: Color
    var onTapDetail: () -> Void

    var body: some View {
        HStack(spacing: 16) {

            // Icon (Bundar)
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .semibold))
            }

            // Title & Total Spend
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.init(hex: "1D2E3E"))

                Text("Rp \(totalSpend, specifier: "%.0f")")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "85ABB8"))
            }

            Spacer()

            // Button Detail
            Button(action: onTapDetail) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
    }
}
