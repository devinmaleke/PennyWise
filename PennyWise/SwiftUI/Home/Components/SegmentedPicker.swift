//
//  SegmentedPicker.swift
//  PennyWise
//
//  Created by Devin Maleke on 20/01/26.
//


import SwiftUI

struct CustomSegmentedControl: View {
    @Binding var selectedOption: Options
    @Environment(\.colorScheme) var colorScheme
    var backgroundColorSegmentedControl: Color {
        colorScheme == .dark ? Color.appFill : Color.gray.opacity(0.14)
    }
    var selectedButtonBackgroundColor: Color {
        Color.appCard
    }
    
    var body: some View {
        HStack {
            ForEach(Options.allCases, id: \.self) { option in
                let isSelected = selectedOption == option
                
                Button {
                    selectedOption = option
                } label: {
                    Text(option.rawValue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .foregroundColor(isSelected ? Color.appInk : Color.appMuted)
                .background(isSelected ? selectedButtonBackgroundColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .padding(.vertical, 2)
                .padding(.horizontal, 2)
                .shadow(color: isSelected ? .secondary : .clear, radius: 2, y: 1)
            }
        }
        .background(backgroundColorSegmentedControl)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
