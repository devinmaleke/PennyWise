//
//  SceneDelegate.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        if window == nil {
            window = UIWindow(windowScene: windowScene)
        }

        guard let window = window else { return }
        AppRouter.configureInitialRoot(in: window)
        AppLockService.shared.prepareForLaunch(windowScene: windowScene)
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {
        AppLockService.shared.handleDidBecomeActive(windowScene: scene as? UIWindowScene)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        AppLockService.shared.handleWillResignActive(windowScene: scene as? UIWindowScene)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {
        AppLockService.shared.handleDidEnterBackground()
    }
}
