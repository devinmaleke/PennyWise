//
//  CustomDivider.swift
//  PennyWise
//
//  Created by Samir iOS on 20/01/26.
//

import SwiftUI

struct CustomDivider: View {
    let color: Color = Color(hex: "F1ECEC")
    let width: CGFloat = 1
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: width)
            .edgesIgnoringSafeArea(.horizontal)
    }
} 
