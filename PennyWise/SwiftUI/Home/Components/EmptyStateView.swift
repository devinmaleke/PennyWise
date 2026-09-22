//
//  EmptyStateView.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import SwiftUI

struct EmptyStateView: View {

    var icon: String = "tray"
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(Color.appMuted)

            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundColor(Color.appInk)

            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(Color.appMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 16)
    }
}
