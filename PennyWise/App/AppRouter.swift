//
//  AppRouter.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import UIKit
import FirebaseAuth

enum AppRouter {

    static func configureInitialRoot(in window: UIWindow) {
        if Auth.auth().currentUser != nil {
            AppearanceStore.shared.apply(to: window)
            UserStore.shared.start()
            FrequentSpendStore.shared.start()
            window.rootViewController = MainTabBarController()
        } else {
            window.overrideUserInterfaceStyle = .light
            window.rootViewController = makeOnboardingNavigation()
        }

        window.makeKeyAndVisible()
    }

    static func showMainApp() {
        UserStore.shared.start()
        FrequentSpendStore.shared.start()
        AppLockService.shared.lockAfterLoginIfNeeded()
        setRoot(MainTabBarController(), usesAppAppearance: true)
    }

    static func showOnboarding() {
        UserStore.shared.stop()
        FrequentSpendStore.shared.stop()
        AppLockService.shared.clearForLogout()
        WidgetSnapshotStore.clear()
        setRoot(makeOnboardingNavigation(), usesAppAppearance: false)
    }

    private static func makeOnboardingNavigation() -> UINavigationController {
        let navigation = UINavigationController(rootViewController: OnboardingVC())
        navigation.setNavigationBarHidden(true, animated: false)
        navigation.overrideUserInterfaceStyle = .light
        return navigation
    }

    private static func setRoot(_ viewController: UIViewController, usesAppAppearance: Bool) {
        guard let window = activeWindow else { return }

        if usesAppAppearance {
            AppearanceStore.shared.apply(to: window)
        } else {
            window.overrideUserInterfaceStyle = .light
        }
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        UIView.transition(
            with: window,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: nil
        )
    }

    private static var activeWindow: UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }

        return windows.first(where: { $0.isKeyWindow }) ?? windows.first
    }
}
