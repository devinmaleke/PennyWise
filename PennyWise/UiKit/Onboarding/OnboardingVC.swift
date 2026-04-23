//
//  OnboardingVC.swift
//  PennyWise
//
//  Created by Samir iOS on 22/01/26.
//

import UIKit

class OnboardingVC: UIViewController {

    @IBOutlet weak var footerBgView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        footerBgView.layer.shadowColor = UIColor.black.cgColor
        footerBgView.layer.shadowOpacity = 0.2
        
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
