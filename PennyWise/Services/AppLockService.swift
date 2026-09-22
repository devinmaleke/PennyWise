//
//  AppLockService.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import Foundation
import LocalAuthentication
import FirebaseAuth
import UIKit
import SwiftUI

final class AppLockService: ObservableObject {

    static let shared = AppLockService()

    private static let enabledKey = "appLockEnabled"

    @Published private(set) var isEnabled: Bool
    @Published private(set) var isLocked: Bool

    private var lockWindow: UIWindow?
    private var isAuthenticating = false
    private var enteredBackground = false
    private var skipNextAutoPrompt = false

    var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Device passcode"
        }
    }

    var canUseLock: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        isLocked = false
    }

    func prepareForLaunch(windowScene: UIWindowScene?) {
        guard shouldProtect else { return }
        isLocked = true
        showOverlay(in: windowScene)
    }

    func setEnabled(_ enabled: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard enabled != isEnabled else {
            completion(.success(()))
            return
        }

        authenticate(reason: enabled ? "Turn on app lock" : "Turn off app lock") { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                self.isEnabled = enabled
                UserDefaults.standard.set(enabled, forKey: Self.enabledKey)
                if !enabled {
                    self.isLocked = false
                    self.hideOverlay()
                }
                completion(.success(()))
            }
        }
    }

    func handleWillResignActive(windowScene: UIWindowScene?) {
        guard shouldProtect, !isAuthenticating else { return }
        showOverlay(in: windowScene)
    }

    func handleDidEnterBackground() {
        guard shouldProtect else { return }
        enteredBackground = true
        isLocked = true
    }

    func handleDidBecomeActive(windowScene: UIWindowScene?) {
        guard shouldProtect else {
            isLocked = false
            hideOverlay()
            return
        }

        if isAuthenticating {
            return
        }

        if isLocked || enteredBackground {
            enteredBackground = false
            isLocked = true
            showOverlay(in: windowScene)
            if skipNextAutoPrompt {
                skipNextAutoPrompt = false
            } else {
                authenticateIfNeeded()
            }
        } else {
            hideOverlay()
        }
    }

    func unlockTapped() {
        authenticateIfNeeded()
    }

    func clearForLogout() {
        isLocked = false
        enteredBackground = false
        hideOverlay()
    }

    func lockAfterLoginIfNeeded() {
        isLocked = false
        enteredBackground = false
        hideOverlay()
    }

    private var shouldProtect: Bool {
        isEnabled && Auth.auth().currentUser != nil
    }

    private func authenticateIfNeeded() {
        guard shouldProtect, isLocked, !isAuthenticating else { return }
        authenticate(reason: "Unlock PennyWise") { [weak self] result in
            switch result {
            case .success:
                self?.isLocked = false
                self?.hideOverlay()
            case .failure(let error):
                if Self.isAuthCancel(error) {
                    self?.skipNextAutoPrompt = true
                }
            }
        }
    }

    private func authenticate(
        reason: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
            completion(.failure(authError ?? Self.lockUnavailableError))
            return
        }

        isAuthenticating = true
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(error ?? Self.lockFailedError))
                }
            }
        }
    }

    private func showOverlay(in windowScene: UIWindowScene?) {
        guard let windowScene = windowScene else { return }

        if lockWindow == nil {
            let hosting = UIHostingController(rootView: AppLockView())
            hosting.view.backgroundColor = UIColor(hex: "1D2E3E")

            let window = UIWindow(windowScene: windowScene)
            window.windowLevel = .alert + 1
            window.rootViewController = hosting
            window.isHidden = false
            lockWindow = window
        }

        lockWindow?.isHidden = false
        lockWindow?.makeKeyAndVisible()
    }

    private func hideOverlay() {
        lockWindow?.isHidden = true
        lockWindow = nil

        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }

        windows.first(where: { $0.rootViewController is MainTabBarController })?
            .makeKeyAndVisible()
    }

    private static func isAuthCancel(_ error: Error) -> Bool {
        let laError = error as? LAError
        return laError?.code == .userCancel || laError?.code == .systemCancel || laError?.code == .appCancel
    }

    private static var lockUnavailableError: NSError {
        NSError(
            domain: "PennyWise",
            code: 403,
            userInfo: [NSLocalizedDescriptionKey: "Set a device passcode in Settings to use app lock"]
        )
    }

    private static var lockFailedError: NSError {
        NSError(
            domain: "PennyWise",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Could not unlock PennyWise"]
        )
    }
}
