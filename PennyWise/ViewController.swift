//
//  ViewController.swift
//  PennyWise
//
//  Created by Samir iOS on 19/01/26.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("MASUK")
        navigationController?.pushViewController(OnboardingVC(), animated: false)
    }
    
//    private func checkLogin(){
//        let token = UserDefaultService.shared.getToken()
//        
//        if token.isNilOrEmpty{
//            navigationController?.pushViewController(LoginVC(), animated: false)
//        } else {
//            navigationController?.pushViewController(HomeVC(), animated: false)
//        }
//    }
}

