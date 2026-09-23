//
//  Functions.swift
//  PennyWise
//
//  Created by Devin Maleke on 04/02/26.
//

import Foundation
import SwiftUI

func inputField(
    title: String,
    text: Binding<String>,
    keyboard: UIKeyboardType = .default,
    backgroundColor: Color = Color.appFill
) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .bold()
            .foregroundColor(Color.appInk)

        TextField(title, text: text)
            .keyboardType(keyboard)
            .padding()
            .background(backgroundColor)
            .cornerRadius(10)
            .foregroundColor(Color.appInk)
            .shadow(radius: 1)
            .padding(.horizontal,2)
    }
}

func secureInputField(
    title: String,
    text: Binding<String>,
    isVisible: Binding<Bool>
) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .bold()
            .foregroundColor(Color.appInk)

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
                    .foregroundColor(Color.appMuted)
            }
        }
        .padding()
        .background(Color.appFill)
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct AmountInputField: View {
    var title: String = "Amount"
    var autofocus: Bool = false
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .bold()
                .foregroundColor(Color.appInk)

            HStack(spacing: 8) {
                Text("Rp")
                    .bold()
                    .foregroundColor(Color.appInk)

                TextField("0", text: $text)
                    .keyboardType(.numberPad)
                    .foregroundColor(Color.appInk)
                    .focused($isFocused)
                    .onChange(of: text) { newValue in
                        let sanitized = AmountParser.sanitizedInput(newValue)
                        if sanitized != newValue {
                            text = sanitized
                        }
                    }
            }
            .padding()
            .background(Color.appFill)
            .cornerRadius(10)
            .shadow(radius: 1)
            .padding(.horizontal,2)
        }
        .onAppear {
            if autofocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    isFocused = true
                }
            }
        }
    }
}

func togglePasswordVisibility(textField: UITextField, button: UIButton) {
    textField.isSecureTextEntry.toggle()

    let imageName = textField.isSecureTextEntry ? "eye.slash" : "eye"
    button.setImage(UIImage(systemName: imageName), for: .normal)
}
