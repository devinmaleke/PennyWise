//
//  AppErrorMapper.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import Foundation
import FirebaseAuth

enum AppErrorMapper {

    enum Context {
        case login
        case passwordChange
        case generic
    }

    static let genericMessage = "Something went wrong. Please try again."

    static func message(for error: Error, context: Context = .generic) -> String {
        let nsError = error as NSError

        if nsError.domain == AuthErrorDomain,
           let code = AuthErrorCode(rawValue: nsError.code) {
            return message(for: code, context: context)
        }

        return nsError.localizedDescription.isEmpty
            ? genericMessage
            : friendlyFallback(nsError.localizedDescription)
    }

    static func message(for code: AuthErrorCode, context: Context = .generic) -> String {
        switch code {
        case .invalidEmail:
            return "Invalid email format"
        case .wrongPassword, .userNotFound, .invalidCredential:
            return context == .passwordChange
                ? "Current password is incorrect"
                : "Wrong email or password"
        case .emailAlreadyInUse:
            return "Email already in use"
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .networkError:
            return "Network error. Check your connection and try again."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        case .userDisabled:
            return "This account has been disabled"
        case .requiresRecentLogin, .invalidUserToken, .userTokenExpired:
            return "Please log in again to continue"
        default:
            return genericMessage
        }
    }

    private static func friendlyFallback(_ localized: String) -> String {
        let lowercased = localized.lowercased()

        if lowercased.contains("network") || lowercased.contains("internet") {
            return "Network error. Check your connection and try again."
        }

        return genericMessage
    }
}
