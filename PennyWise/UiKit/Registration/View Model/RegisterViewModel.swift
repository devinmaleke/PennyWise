//
//  RegisterViewModel.swift
//  PennyWise
//
//  Created by Samir iOS on 30/01/26.
//

import FirebaseAuth
import FirebaseFirestore

class RegisterViewModel {

    var onRegisterSuccess: (() -> Void)?
    var onError: ((String) -> Void)?

    func register(name: String, email: String, password: String) {

        guard !name.isEmpty,
              !email.isEmpty,
              !password.isEmpty else {
            onError?("All fields are required")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in

            if let error = error {
                self?.handleFirebaseError(error)
                return
            }

            guard let uid = result?.user.uid else { return }

            self?.saveUserToFirestore(
                uid: uid,
                name: name,
                email: email
            )
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
                    self?.onError?(error.localizedDescription)
                } else {
                    self?.onRegisterSuccess?()
                }
            }
    }

    private func handleFirebaseError(_ error: Error) {
        let nsError = error as NSError

        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            onError?("Email already in use")
        case AuthErrorCode.invalidEmail.rawValue:
            onError?("Invalid email format")
        case AuthErrorCode.weakPassword.rawValue:
            onError?("Password is too weak")
        default:
            onError?(nsError.localizedDescription)
        }
    }
}

