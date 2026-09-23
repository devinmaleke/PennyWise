//
//  RegisterViewModel.swift
//  PennyWise
//
//  Created by Devin Maleke on 30/01/26.
//

import FirebaseFirestore

class RegisterViewModel {

    var onLoading: ((Bool) -> Void)?
    var onRegisterSuccess: (() -> Void)?
    var onError: ((String) -> Void)?

    func register(name: String, email: String, password: String, confirmPass: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty, !confirmPass.isEmpty else {
            onError?("All fields are required")
            return
        }

        guard password.count >= 6 else {
            onError?("Password must be at least 6 characters")
            return
        }
        
        guard password == confirmPass else {
            onError?("Password do not match")
            return
        }

        onLoading?(true)

        AuthService.shared.register(email: trimmedEmail, password: password) { [weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.onLoading?(false)
                    self?.onError?(AppErrorMapper.message(for: error))
                }
            case .success(let uid):
                self?.saveUserToFirestore(
                    uid: uid,
                    name: trimmedName,
                    email: trimmedEmail
                )
            }
        }
    }

    private func saveUserToFirestore(uid: String, name: String, email: String) {
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData([
                "name": name,
                "email": email,
                "createdAt": Timestamp()
            ]) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.onLoading?(false)
                        self?.onError?(AppErrorMapper.message(for: error))
                    }
                    return
                }

                DefaultCategorySeeder.seedIfNeeded(for: uid) { _ in
                    DispatchQueue.main.async {
                        self?.onLoading?(false)
                        self?.onRegisterSuccess?()
                    }
                }
            }
    }
}
