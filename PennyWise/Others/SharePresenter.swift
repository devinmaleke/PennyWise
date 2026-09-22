//
//  SharePresenter.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import UIKit
import SwiftUI

enum SharePresenter {

    static func present(items: [Any]) {
        guard let presenter = topViewController() else { return }

        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        presenter.present(controller, animated: true)
    }

    static func image<Content: View>(from view: Content, size: CGSize) -> UIImage? {
        guard let parent = topViewController() else { return nil }

        let root = view
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .background(Color.white)
            .environment(\.colorScheme, .light)

        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = .white
        hosting.view.overrideUserInterfaceStyle = .light
        hosting.additionalSafeAreaInsets = UIEdgeInsets(
            top: -(parent.view.safeAreaInsets.top),
            left: 0,
            bottom: -(parent.view.safeAreaInsets.bottom),
            right: 0
        )

        parent.addChild(hosting)
        hosting.view.frame = CGRect(origin: CGPoint(x: -size.width, y: 0), size: size)
        parent.view.addSubview(hosting.view)
        hosting.didMove(toParent: parent)

        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        parent.view.layoutIfNeeded()
        CATransaction.flush()

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { _ in
            hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
        }

        hosting.willMove(toParent: nil)
        hosting.view.removeFromSuperview()
        hosting.removeFromParent()
        return image
    }

    private static func keyWindow() -> UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }

        return windows.first(where: { $0.isKeyWindow }) ?? windows.first
    }

    private static func topViewController() -> UIViewController? {
        var current = keyWindow()?.rootViewController
        while let presented = current?.presentedViewController {
            current = presented
        }
        return current
    }
}
