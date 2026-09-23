//
//  RegisterVC.swift
//  PennyWise
//
//  Created by Devin Maleke on 22/01/26.
//

import UIKit

class RegisterVC: UIViewController {

    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var confirmPassTF: UITextField!
    @IBOutlet weak var revealPassButton: UIButton!
    @IBOutlet weak var revealConfirmPassButton: UIButton!
    
    private let viewModel = RegisterViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .white
        bindViewModel()
        backButton.setTitle("", for: .normal)
    }

    private func bindViewModel() {
        viewModel.onLoading = { [weak self] isLoading in
            self?.setLoading(isLoading)
        }

        viewModel.onRegisterSuccess = {
            AppRouter.showMainApp()
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message)
        }
    }

    @IBAction func didTapRegister(_ sender: UIButton) {
        viewModel.register(
            name: nameTF.text ?? "",
            email: emailTF.text ?? "",
            password: passwordTF.text ?? "",
            confirmPass: confirmPassTF.text ?? ""
        )
    }

    @IBAction func didTapBackButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func didTapRevealPassButton(_ sender: UIButton) {
        togglePasswordVisibility(
                textField: passwordTF,
                button: sender
            )
    }
    
    @IBAction func didTapRevealConfirmPassButton(_ sender: UIButton) {
        togglePasswordVisibility(
                textField: confirmPassTF,
                button: sender
            )
    }
}
