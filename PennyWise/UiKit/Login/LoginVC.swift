//
//  LoginVC.swift
//  PennyWise
//
//  Created by Samir iOS on 22/01/26.
//

import UIKit

class LoginVC: UIViewController {

    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    
    @IBOutlet weak var backButton: UIButton!
    
    private let viewModel = LoginViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        backButton.titleLabel?.text = ""
    }

    @IBAction func didTapButton(_ sender: UIButton) {
        viewModel.email = usernameTF.text ?? ""
        viewModel.password = passwordTF.text ?? ""
        viewModel.login()
    }
    
    
    @IBAction func didTapBackButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func bindViewModel() {
        viewModel.onLoading = { isLoading in
            if isLoading {
                print("Loading...")
                // show loader
            } else {
                print("Stop loading")
                // hide loader
            }
        }

        viewModel.onSuccess = { [weak self] in
            let mainTab = MainTabBarController()
            mainTab.modalPresentationStyle = .fullScreen
            self?.present(mainTab, animated: true)
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message)
        }
    }
    
}
