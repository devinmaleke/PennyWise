//
//  AuthService.swift
//  PennyWise
//
//  Created by Devin Maleke on 30/01/26.
//

import FirebaseAuth
import Foundation

final class AuthService {

    static let shared = AuthService()
    private init() {}

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func login(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func register(
        email: String,
        password: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let uid = result?.user.uid else {
                completion(.failure(NSError(
                    domain: AuthErrorDomain,
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: AppErrorMapper.genericMessage]
                )))
                return
            }

            completion(.success(uid))
        }
    }

    func logout() throws {
        try Auth.auth().signOut()
    }
}

