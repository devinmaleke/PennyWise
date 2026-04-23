//
//  RegisterVC.swift
//  PennyWise
//
//  Created by Samir iOS on 22/01/26.
//

import UIKit

class RegisterVC: UIViewController {

    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    private let viewModel = RegisterViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        backButton.titleLabel?.text = ""
    }

    private func bindViewModel() {
        viewModel.onRegisterSuccess = { [weak self] in
            DispatchQueue.main.async {
                let mainTab = LoginVC()
                mainTab.modalPresentationStyle = .fullScreen
                self?.present(mainTab, animated: true)
            }
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message)
        }
    }

    @IBAction func didTapRegister(_ sender: UIButton) {
        viewModel.register(
            name: nameTF.text ?? "",
            email: emailTF.text ?? "",
            password: passwordTF.text ?? ""
        )
    }
    
    @IBAction func didTapBackButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
