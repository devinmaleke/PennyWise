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

    private let viewModel = RegisterViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        backButton.setTitle("", for: .normal)
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
        AuthAppearance.apply(
            to: self,
            fields: [nameTF, emailTF, passwordTF],
            backButton: backButton,
            filledButtons: [registerButton]
        )
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
            password: passwordTF.text ?? ""
        )
    }

    @IBAction func didTapBackButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
