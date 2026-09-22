//
//  LoginViewModel.swift
//  PennyWise
//
//  Created by Devin Maleke on 30/01/26.
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
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            onError?("Email and password cannot be empty")
            return
        }

        onLoading?(true)

        AuthService.shared.login(email: trimmedEmail, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoading?(false)

                switch result {
                case .success:
                    self?.onSuccess?()
                case .failure(let error):
                    self?.onError?(AppErrorMapper.message(for: error))
                }
            }
        }
    }
}
