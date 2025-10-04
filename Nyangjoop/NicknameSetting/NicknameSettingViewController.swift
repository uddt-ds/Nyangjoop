//
//  NicknameSettingViewController.swift
//  Nyangjoop
//
//  Created by Lee on 10/3/25.
//

import UIKit
import SnapKit

final class NicknameSettingViewController: BaseViewController {
    
    // MARK: - UI Components
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.numberOfLines = 0
        return label
    }()
    
    private let nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = ""
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .label
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1.5
        textField.layer.borderColor = UIColor.systemOrange.cgColor
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = paddingView
        textField.rightViewMode = .always
        
        return textField
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("설정하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = .key
        button.layer.cornerRadius = 16
        return button
    }()
    
    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("그냥 묘험가로 할게", for: .normal)
        button.setTitleColor(.appTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.backgroundColor = .clear
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitleLabel()
        setupActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nicknameTextField.becomeFirstResponder()
    }
    
    // MARK: - Configuration
    
    override func configureHierarchy() {
        super.configureHierarchy()
        
        [titleLabel, nicknameTextField, saveButton, skipButton].forEach {
            view.addSubview($0)
        }
    }
    
    override func configureLayout() {
        super.configureLayout()
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(180)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        nicknameTextField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(nicknameTextField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }
        
        skipButton.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }
    }
    
    override func configureView() {
        super.configureView()
        view.backgroundColor = .appBg
    }
    
    // MARK: - Setup
    
    private func setupTitleLabel() {
        let fullText = "묘험가님, 이름을 어떻게 불러드릴까요?♧"
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // "," 기준으로 분리
        if let commaRange = fullText.range(of: ",") {
            let beforeComma = fullText[..<commaRange.lowerBound]

            // 앞부분: key 컬러
            let beforeRange = NSRange(location: 0, length: beforeComma.count)
            attributedString.addAttribute(.foregroundColor, value: UIColor(named: "key") ?? .systemOrange, range: beforeRange)
            
            // "," 포함 뒷부분: appTitle 컬러
            let afterRange = NSRange(location: beforeComma.count, length: fullText.count - beforeComma.count)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: afterRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor(named: "appTitle") ?? .label, range: afterRange)
        }
        
        titleLabel.attributedText = attributedString
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func saveButtonTapped() {
        guard let nickname = nicknameTextField.text, !nickname.isEmpty else {
            showAlert(message: "닉네임을 입력해주세요")
            return
        }
        
        UserDefaults.standard.set(nickname, forKey: "nickname")
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        navigateToMainScreen()
    }
    
    @objc private func skipButtonTapped() {
        UserDefaults.standard.set("냥집사", forKey: "nickname")
        navigateToMainScreen()
    }
    
    private func navigateToMainScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let tabBarController = CustomTabBarController()
        window.rootViewController = tabBarController
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
