//
//  SearchField.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import SwiftUI

struct SearchField: View {

    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.appMuted)

            TextField(placeholder, text: $text)
                .foregroundColor(Color.appInk)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.appMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.appCard)
        .cornerRadius(10)
        .shadow(radius: 0.5)
    }
}
