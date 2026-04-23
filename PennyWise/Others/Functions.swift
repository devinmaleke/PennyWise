//
//  Functions.swift
//  PennyWise
//
//  Created by Samir iOS on 04/02/26.
//

import Foundation
import SwiftUI

public func inputField(
    title: String,
    text: Binding<String>,
    keyboard: UIKeyboardType = .default,
    backgroundColor: Color = .white
) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .bold()
            .foregroundColor(Color(hex: "1D2E3E"))

        TextField(title, text: text)
            .keyboardType(keyboard)
            .padding()
            .background(backgroundColor)
            .cornerRadius(10)
            .foregroundColor(.black)
            .shadow(radius: 1)
    }
}

public func secureInputField(
    title: String,
    text: Binding<String>,
    isVisible: Binding<Bool>
) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .bold()
            .foregroundColor(Color(hex: "1D2E3E"))

        HStack {
            if isVisible.wrappedValue {
                TextField(title, text: text)
            } else {
                SecureField(title, text: text)
            }

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}
