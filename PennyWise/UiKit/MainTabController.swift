//
//  MainTabController.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import UIKit
import SwiftUI

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupTabBarAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupTabBarAppearance()
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .pwCard
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .pwInk
        tabBar.unselectedItemTintColor = .pwMuted
    }
    
    private func setupTabs() {
        let home = makeTab(
            view: HomeView(),
            title: "Home",
            image: UIImage(systemName: "house.fill")
        )

        let history = makeTab(
            view: HistoryView(),
            title: "History",
            image: UIImage(systemName: "list.bullet")
        )

        let summary = makeTab(
            view: SummaryView(),
            title: "Summary",
            image: UIImage(systemName: "chart.pie.fill")
        )

        let settings = makeTab(
            view: ProfileView(),
            title: "Profile",
            image: UIImage(systemName: "person.fill")
        )

        viewControllers = [home, history, summary, settings]
    }

    private func makeTab<Content: View>(
        view: Content,
        title: String,
        image: UIImage?
    ) -> UIViewController {

        let hosting = UIHostingController(rootView: view)
        hosting.view.backgroundColor = .clear
        hosting.tabBarItem = UITabBarItem(title: title, image: image, selectedImage: nil)
        return hosting
    }
}
