//
//  OnboardingVC.swift
//  PennyWise
//
//  Created by Devin Maleke on 22/01/26.
//

import UIKit

class OnboardingVC: UIViewController {

    @IBOutlet weak var footerBgView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
    }

    @IBAction func didTapButton(_ sender: UIButton) {
        if sender.tag == 0 {
            navigationController?.pushViewController(LoginVC(), animated: true)
        } else {
            navigationController?.pushViewController(RegisterVC(), animated: true)
        }
    }
}
