//
//  LoginVC.swift
//  PennyWise
//
//  Created by Devin Maleke on 22/01/26.
//

import UIKit

class LoginVC: UIViewController {

    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!

    @IBOutlet weak var backButton: UIButton!

    @IBOutlet weak var revealPassButton: UIButton!
    private let viewModel = LoginViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .white
        bindViewModel()
        backButton.setTitle("", for: .normal)
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
        viewModel.onLoading = { [weak self] isLoading in
            self?.setLoading(isLoading)
        }

        viewModel.onSuccess = {
            AppRouter.showMainApp()
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message)
        }
    }
    
    
    @IBAction func revealPassButton(_ sender: UIButton) {
        togglePasswordVisibility(
                textField: passwordTF,
                button: sender
            )
    }
}
