//
//  ProfileViewModel.swift
//  PennyWise
//
//  Created by Samir iOS on 05/02/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewModel: ObservableObject {

    @Published var name: String = ""
    @Published var email: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private var originalName: String = ""

    private let db = Firestore.firestore()

    init() {
        fetchProfile()
    }

    // MARK: - Fetch Profile
    func fetchProfile() {
        guard let user = Auth.auth().currentUser else { return }

        email = user.email ?? ""

        db.collection("users")
            .document(user.uid)
            .getDocument { [weak self] snap, _ in
                self?.name = snap?.data()?["name"] as? String ?? ""
                self?.originalName = self?.name ?? ""
            }
    }
    
    var isNameChanged: Bool {
           name.trimmingCharacters(in: .whitespacesAndNewlines) != originalName
       }


    // MARK: - Update Name
    func updateName() {
        guard isNameChanged,
                     let uid = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        db.collection("users")
            .document(uid)
            .updateData([
                "name": name
            ]) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        self?.successMessage = "Name updated successfully"
                    }
                }
            }
    }

    // MARK: - Change Password
    func changePassword(
        currentPassword: String,
        newPassword: String
    ) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        let credential = EmailAuthProvider.credential(
            withEmail: email,
            password: currentPassword
        )

        // Re-auth
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            // Update password
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        self?.successMessage = "Password updated successfully"
                    }
                }
            }
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
           print("Logout failed: \(error.localizedDescription)")
        }
    }
}

