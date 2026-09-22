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
        applyAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyAppearance()
    }

    private func applyAppearance() {
        view.backgroundColor = .pwBackground
        footerBgView.backgroundColor = .pwCard
        footerBgView.layer.shadowColor = UIColor.black.cgColor
        footerBgView.layer.shadowOpacity = Palette.isDark() ? 0.35 : 0.2

        footerBgView.subviews.compactMap { $0 as? UIButton }.forEach { button in
            if button.tag == 1 {
                AuthAppearance.styleSecondaryButton(button)
            } else {
                AuthAppearance.styleFilledButton(button)
            }
        }
    }
    
    
    @IBAction func didTapButton(_ sender: UIButton) {
        if sender.tag == 0{
            //Login
            self.navigationController?.pushViewController(LoginVC(), animated: true)
        }else{
            //register
            self.navigationController?.pushViewController(RegisterVC(), animated: true)
        }
    }
    

}
