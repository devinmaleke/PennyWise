//
//  ProfileViewModel.swift
//  PennyWise
//
//  Created by Devin Maleke on 05/02/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import LocalAuthentication

final class ProfileViewModel: ObservableObject {

    @Published var name: String = ""
    @Published var email: String = ""
    @Published var isLoading = false
    @Published var isExporting = false
    @Published var exportPeriod: ExportPeriod = .thisMonth
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
                let name = snap?.data()?["name"] as? String ?? ""
                DispatchQueue.main.async {
                    self?.name = name
                    self?.originalName = name
                }
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
                        self?.errorMessage = AppErrorMapper.message(for: error)
                    } else {
                        self?.successMessage = "Name updated successfully"
                    }
                }
            }
    }

    // MARK: - Change Password
    func changePassword(
        currentPassword: String,
        newPassword: String,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            errorMessage = "Please log in again to continue"
            completion?(false)
            return
        }

        let trimmedCurrent = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNew = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCurrent.isEmpty else {
            errorMessage = "Current password is required"
            completion?(false)
            return
        }

        guard trimmedNew.count >= 6 else {
            errorMessage = "Password is too weak. Use at least 6 characters."
            completion?(false)
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        let credential = EmailAuthProvider.credential(
            withEmail: email,
            password: trimmedCurrent
        )

        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = AppErrorMapper.message(
                        for: error,
                        context: .passwordChange
                    )
                    completion?(false)
                }
                return
            }

            user.updatePassword(to: trimmedNew) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = AppErrorMapper.message(
                            for: error,
                            context: .passwordChange
                        )
                        completion?(false)
                    } else {
                        self?.successMessage = "Password updated successfully"
                        completion?(true)
                    }
                }
            }
        }
    }
    
    func setAppLock(_ enabled: Bool) {
        errorMessage = nil
        AppLockService.shared.setEnabled(enabled) { [weak self] result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    if Self.isAuthCancel(error) {
                        return
                    }
                    self?.errorMessage = AppErrorMapper.message(for: error)
                }
            }
        }
    }

    func exportCSV() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Please log in again to continue"
            return
        }

        isExporting = true
        errorMessage = nil
        successMessage = nil

        let period = exportPeriod

        db.collection("users")
            .document(uid)
            .collection("transactions")
            .order(by: "date", descending: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    DispatchQueue.main.async {
                        self.isExporting = false
                        self.errorMessage = AppErrorMapper.message(for: error)
                    }
                    return
                }

                let all = snapshot?.documents.compactMap {
                    TransactionModel.from(document: $0)
                } ?? []

                let filtered: [TransactionModel]
                if let range = period.dateRange {
                    filtered = all.filter { $0.date >= range.start && $0.date <= range.end }
                } else {
                    filtered = all
                }

                DispatchQueue.main.async {
                    self.isExporting = false

                    guard !filtered.isEmpty else {
                        self.errorMessage = "No transactions in this period"
                        return
                    }

                    do {
                        let url = try TransactionCSV.writeTemporaryFile(
                            from: filtered,
                            period: period
                        )
                        SharePresenter.present(items: [url])
                    } catch {
                        self.errorMessage = AppErrorMapper.message(for: error)
                    }
                }
            }
    }

    private static func isAuthCancel(_ error: Error) -> Bool {
        let laError = error as? LAError
        return laError?.code == .userCancel || laError?.code == .systemCancel || laError?.code == .appCancel
    }

    func logout() {
        do {
            try AuthService.shared.logout()
            DispatchQueue.main.async {
                AppRouter.showOnboarding()
            }
        } catch {
            errorMessage = AppErrorMapper.message(for: error)
        }
    }
}

