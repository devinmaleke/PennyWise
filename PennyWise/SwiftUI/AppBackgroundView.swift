//
//  AppBackgroundView.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import SwiftUI

struct AppBackgroundView: View {

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "FAFAFA"), // atas
                Color(hex: "FAFAFA")  // bawah
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
