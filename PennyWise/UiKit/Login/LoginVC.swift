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

    private let viewModel = LoginViewModel()

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
            fields: [usernameTF, passwordTF],
            backButton: backButton
        )
        view.subviews.compactMap { $0 as? UIButton }.filter { $0 !== backButton }.forEach {
            AuthAppearance.styleFilledButton($0)
        }
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
}
