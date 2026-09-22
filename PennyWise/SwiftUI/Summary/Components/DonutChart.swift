//
//  DonutChart.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import SwiftUI

struct DonutChart: View {
    let slices: [CategorySlice]
    var lineWidth: CGFloat = 28

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appFill, lineWidth: lineWidth)

            ForEach(slices) { slice in
                Circle()
                    .trim(from: CGFloat(slice.startFraction), to: CGFloat(slice.endFraction))
                    .stroke(
                        Color(hex: slice.colorHex),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(8)
    }
}

struct ComparisonBar: View {
    let incomeShare: Double
    let spendShare: Double

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            HStack(spacing: 0) {
                if incomeShare > 0 {
                    Rectangle()
                        .fill(Color(hex: "27AE60"))
                        .frame(width: width * CGFloat(incomeShare))
                }
                if spendShare > 0 {
                    Rectangle()
                        .fill(Color(hex: "E74C3C"))
                        .frame(width: width * CGFloat(spendShare))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Color.appFill)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(height: 14)
    }
}
