//
//  AppBackgroundView.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import SwiftUI

struct AppBackgroundView: View {

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.appBackground, // atas
                Color.appBackground  // bawah
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
