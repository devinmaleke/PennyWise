//
//  CategoryColorPicker.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import SwiftUI

enum CategoryColorPalette {
    static let hexes: [String] = [
        "#E74C3C",
        "#E67E22",
        "#F1C40F",
        "#27AE60",
        "#1ABC9C",
        "#3498DB",
        "#9B59B6",
        "#E91E63",
        "#8E44AD",
        "#D35400",
        "#1D2E3E",
        "#466C85"
    ]
}

struct CategoryColorPicker: View {

    @Binding var selectedHex: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    private var colors: [String] {
        var list = CategoryColorPalette.hexes
        if !selectedHex.isEmpty && !list.contains(where: { isSelected($0) }) {
            list.append(selectedHex)
        }
        return list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .bold()
                .foregroundColor(Color.appInk)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(colors, id: \.self) { hex in
                    Button {
                        selectedHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: isSelected(hex) ? 3 : 0)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        Color.appInk,
                                        lineWidth: isSelected(hex) ? 2 : 0
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Color \(hex)")
                    .accessibilityAddTraits(isSelected(hex) ? .isSelected : [])
                }
            }
        }
    }

    private func isSelected(_ hex: String) -> Bool {
        hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
            == selectedHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
    }
}
