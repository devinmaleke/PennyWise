//
//  LoginViewModel.swift
//  PennyWise
//
//  Created by Samir iOS on 30/01/26.
//

import Foundation

final class LoginViewModel {

    // MARK: - Inputs
    var email: String = ""
    var password: String = ""

    // MARK: - Outputs
    var onLoading: ((Bool) -> Void)?
    var onSuccess: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Action
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            onError?("Email dan password tidak boleh kosong")
            return
        }

        onLoading?(true)

        AuthService.shared.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoading?(false)

                switch result {
                case .success:
                    self?.onSuccess?()
                case .failure(let error):
                    let nsError = error as NSError
                    print("Firebase Error Code:", nsError.code)
                    print("Firebase Error:", nsError.localizedDescription)
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }
}

