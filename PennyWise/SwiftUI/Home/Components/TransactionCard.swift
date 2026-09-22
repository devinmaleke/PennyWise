//
//  TransactionCard.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import SwiftUI

struct TransactionCardView: View {

    let title: String
    let note: String
    let category: String
    let date: String
    let amount: String
    let isIncome: Bool
    var colorHex: String = "#1D2E3E"
    var showsDivider: Bool = true
    var isRecurring: Bool = false
    var onTap: (() -> Void)? = nil
    var onAddAgain: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 12) {
                    categoryDot

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(title)
                                .font(.body)
                                .bold()
                                .foregroundColor(Color.appInk)

                            if isRecurring {
                                Image(systemName: "repeat")
                                    .font(.caption2)
                                    .foregroundColor(Color.appMuted)
                            }
                        }

                        if !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundColor(Color.appMuted)
                                .lineLimit(2)
                        }

                        Text(category)
                            .font(.caption)
                            .foregroundColor(Color.appMuted)

                        Text(date)
                            .font(.caption2)
                            .foregroundColor(Color.appMuted)
                    }

                    Spacer(minLength: 8)

                    Text(amount)
                        .font(.body)
                        .bold()
                        .foregroundColor(isIncome ? Color(hex: "27AE60") : Color(hex: "E74C3C"))
                }
                .padding(.vertical)
                .padding(.leading)
                .padding(.trailing, onAddAgain == nil ? 16 : 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?()
                }

                if let onAddAgain = onAddAgain {
                    Button(action: onAddAgain) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color.appInk)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Add again today")
                    .padding(.trailing, 8)
                }
            }

            if showsDivider {
                CustomDivider()
                    .padding(.horizontal)
            }
        }
    }

    private var categoryDot: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex).opacity(0.15))
                .frame(width: 36, height: 36)

            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 10, height: 10)
        }
    }
}
