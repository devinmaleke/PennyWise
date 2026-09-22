//
//  FrequentSpendRow.swift
//  PennyWise
//
//  Created by Devin Maleke on 22/09/26.
//

import SwiftUI

struct FrequentSpendRow: View {

    let items: [FrequentSpend]
    var lastAmount: (FrequentSpend) -> Int
    var onSelect: (FrequentSpend) -> Void
    var onRemove: (FrequentSpend) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequent")
                .bold()
                .foregroundColor(Color.appInk)

            if items.isEmpty {
                Text("Pin lunch, dinner, or MRT from Add again or a transaction")
                    .font(.caption)
                    .foregroundColor(Color.appMuted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                chip(for: item)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button {
                                    onSelect(item)
                                } label: {
                                    Label("Add again", systemImage: "plus.circle")
                                }

                                Button(role: .destructive) {
                                    onRemove(item)
                                } label: {
                                    Label("Remove from Home", systemImage: "star.slash")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card(for: colorScheme))
        .cornerRadius(8)
        .shadow(radius: 0.5)
    }

    private func chip(for item: FrequentSpend) -> some View {
        let amount = lastAmount(item)

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: item.category.colorHex).opacity(0.15))
                    .frame(width: 40, height: 40)

                Circle()
                    .fill(Color(hex: item.category.colorHex))
                    .frame(width: 10, height: 10)
            }

            Text(item.title)
                .font(.caption)
                .bold()
                .foregroundColor(Color.appInk)
                .lineLimit(1)

            Text(amount > 0 ? amount.asRupiah : item.category.name)
                .font(.caption2)
                .foregroundColor(Color.appMuted)
                .lineLimit(1)
        }
        .frame(width: 88)
        .padding(.vertical, 10)
        .background(Color.chip(for: colorScheme))
        .cornerRadius(12)
        .accessibilityLabel("Add \(item.title) again")
    }
}
