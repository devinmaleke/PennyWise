//
//  AppLockView.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import SwiftUI

struct AppLockView: View {

    var body: some View {
        ZStack {
            Color(hex: "1D2E3E")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)

                Text("PennyWise")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                Text("Unlock to see your transactions")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))

                Button {
                    AppLockService.shared.unlockTapped()
                } label: {
                    Text("Unlock with \(AppLockService.shared.biometryName)")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(Color(hex: "1D2E3E"))
                        .cornerRadius(12)
                }
                .padding(.top, 12)
                .padding(.horizontal, 32)
            }
        }
    }
}
