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
        AppearanceStore.shared.apply(to: window)

        if Auth.auth().currentUser != nil {
            UserStore.shared.start()
            FrequentSpendStore.shared.start()
            window.rootViewController = MainTabBarController()
        } else {
            window.rootViewController = makeOnboardingNavigation()
        }

        window.makeKeyAndVisible()
    }

    static func showMainApp() {
        UserStore.shared.start()
        FrequentSpendStore.shared.start()
        AppLockService.shared.lockAfterLoginIfNeeded()
        setRoot(MainTabBarController())
    }

    static func showOnboarding() {
        UserStore.shared.stop()
        FrequentSpendStore.shared.stop()
        AppLockService.shared.clearForLogout()
        WidgetSnapshotStore.clear()
        setRoot(makeOnboardingNavigation())
    }

    private static func makeOnboardingNavigation() -> UINavigationController {
        let navigation = UINavigationController(rootViewController: OnboardingVC())
        navigation.setNavigationBarHidden(true, animated: false)
        return navigation
    }

    private static func setRoot(_ viewController: UIViewController) {
        guard let window = activeWindow else { return }

        AppearanceStore.shared.apply(to: window)
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
