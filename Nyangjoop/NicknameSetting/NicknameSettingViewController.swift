//
//  NicknameSettingViewController.swift
//  Nyangjoop
//
//  Created by Lee on 10/3/25.
//

import UIKit
import SnapKit

final class NicknameSettingViewController: BaseViewController {
    
    // MARK: - Properties
    
    var onNicknameUpdated: ((String) -> Void)?
    
    private var isEditMode: Bool {
        return UserDefaults.standard.string(forKey: "nickname") != nil
    }
    
    // MARK: - UI Components
    
    private let titleLabel: UILabel = {
        let label = UILabel()
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
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "닉네임은 12글자 이하만 가능합니다"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let maxNicknameLength = 12
    
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
        button.titleLabel?.font = UIFont(name: "MemomentKkukkukkR", size: 14) ?? .systemFont(ofSize: 14)
        button.backgroundColor = .clear
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureForMode()
        setupTitleLabel()
        setupActions()
        setupTextFieldDelegate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isEditMode {
            hideCustomTabBar()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nicknameTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isEditMode {
            showCustomTabBar()
        }
    }
    
    // MARK: - Configuration
    
    override func configureHierarchy() {
        super.configureHierarchy()
        
        [titleLabel, nicknameTextField, infoLabel, saveButton, skipButton].forEach {
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
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(nicknameTextField.snp.bottom).offset(8)
            make.leading.equalTo(nicknameTextField).offset(4)
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }
        
        skipButton.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom)
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
        }
    }
    
    override func configureView() {
        super.configureView()
        view.backgroundColor = .appBg
    }
    
    // MARK: - Setup
    
    private func hideCustomTabBar() {
        var currentVC: UIViewController? = self
        while let parent = currentVC?.parent {
            currentVC = parent
            if let tabBarController = parent as? CustomTabBarController {
                tabBarController.hideTabBar()
                return
            }
        }
    }
    
    private func showCustomTabBar() {
        var currentVC: UIViewController? = self
        while let parent = currentVC?.parent {
            currentVC = parent
            if let tabBarController = parent as? CustomTabBarController {
                tabBarController.showTabBar()
                return
            }
        }
    }
    
    private func configureForMode() {
        if isEditMode {
            skipButton.isHidden = true
            
            if let currentNickname = UserDefaults.standard.string(forKey: "nickname") {
                nicknameTextField.text = currentNickname
            }
        }
    }
    
    private func setupTitleLabel() {
        let fullText: String
        if isEditMode {
            let currentNickname = UserDefaults.standard.string(forKey: "nickname") ?? "묘험가"
            let displayNickname: String
            
            if currentNickname.count > 7 {
                let startIndex = currentNickname.index(currentNickname.startIndex, offsetBy: 3)
                let endIndex = currentNickname.index(currentNickname.endIndex, offsetBy: -3)
                displayNickname = String(currentNickname[..<startIndex]) + "..." + String(currentNickname[endIndex...])
            } else {
                displayNickname = currentNickname
            }
            
            fullText = "\(displayNickname)님, 어떤 이름으로 변경할까요?♧"
        } else {
            fullText = "묘험가님, 이름을 어떻게 불러드릴까요?♧"
        }
        
        let attributedString = NSMutableAttributedString(string: fullText)
        
        if let commaRange = fullText.range(of: ",") {
            let beforeComma = fullText[..<commaRange.lowerBound]

            let beforeRange = NSRange(location: 0, length: beforeComma.count)
            attributedString.addAttribute(.font, value: FontSystem.main.font, range: beforeRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor(named: "key") ?? .systemOrange, range: beforeRange)
            
            let afterRange = NSRange(location: beforeComma.count, length: fullText.count - beforeComma.count)
            attributedString.addAttribute(.font, value: FontSystem.body.font, range: afterRange)
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
    
    private func setupTextFieldDelegate() {
        nicknameTextField.delegate = self
        nicknameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange() {
        guard let text = nicknameTextField.text else { return }
        
        if text.count > maxNicknameLength {
            updateInfoLabel(message: "닉네임은 12글자 이하만 가능합니다", isError: true)
        } else if containsSpecialCharacters(text) {
            updateInfoLabel(message: "특수문자는 입력이 불가능합니다", isError: true)
        } else {
            updateInfoLabel(message: "닉네임은 12글자 이하만 가능합니다", isError: false)
        }
    }
    
    private func containsSpecialCharacters(_ text: String) -> Bool {
        let pattern = "[^a-zA-Z0-9가-힣ㄱ-ㅎㅏ-ㅣ\\s]"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex?.firstMatch(in: text, range: range) != nil
    }
    
    private func updateInfoLabel(message: String, isError: Bool) {
        infoLabel.text = message
        infoLabel.textColor = isError ? .systemRed : .secondaryLabel
    }
    
    @objc private func saveButtonTapped() {
        guard let nickname = nicknameTextField.text, !nickname.isEmpty else {
            showAlert(message: "닉네임을 입력해주세요")
            return
        }
        
        if nickname.count > maxNicknameLength {
            showAlert(message: "닉네임은 12글자 이하로 입력해주세요")
            return
        }
        
        if containsSpecialCharacters(nickname) {
            showAlert(message: "특수문자는 사용할 수 없습니다")
            return
        }
        
        UserDefaults.standard.set(nickname, forKey: "nickname")
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        if isEditMode {
            onNicknameUpdated?(nickname)
            navigationController?.popViewController(animated: true)
        } else {
            navigateToMainScreen()
        }
    }
    
    @objc private func skipButtonTapped() {
        UserDefaults.standard.set("묘험가", forKey: "nickname")
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

extension NicknameSettingViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newText = (text as NSString).replacingCharacters(in: range, with: string)
        return newText.count <= 12
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
