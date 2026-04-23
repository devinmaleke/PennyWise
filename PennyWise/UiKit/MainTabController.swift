//
//  MainTabController.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import UIKit
import SwiftUI

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupTabBarAppearance()
    }

    private func setupTabBarAppearance() {
        // Background
        tabBar.barTintColor = .white
        tabBar.backgroundColor = .white

        // Selected item
        tabBar.tintColor = UIColor.init(hex: "1D2E3E")

        // Unselected item
        if #available(iOS 10.0, *) {
            tabBar.unselectedItemTintColor = UIColor.init(hex: "DDDDDD")
        }
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

//        let summary = makeTab(
//            view: HomeView(),
//            title: "Summary",
//            image: UIImage(systemName: "chart.pie.fill")
//        )

        let settings = makeTab(
            view: ProfileView(),
            title: "Profile",
            image: UIImage(systemName: "person.fill")
        )

        viewControllers = [home, history, settings]
    }

    private func makeTab<Content: View>(
        view: Content,
        title: String,
        image: UIImage?
    ) -> UIViewController {

        let hosting = UIHostingController(rootView: view)
        hosting.tabBarItem = UITabBarItem(title: title, image: image, selectedImage: nil)
        return hosting
    }
}

