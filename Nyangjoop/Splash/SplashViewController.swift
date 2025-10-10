//
//  SplashViewController.swift
//  Nyangjoop
//
//  Created by Lee on 10/4/25.
//

import UIKit
import SnapKit

final class SplashViewController: BaseViewController {

    private let splashImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "splash")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureLayout()
        navigateToNextScreen()
    }
    
    override func configureHierarchy() {
        view.addSubview(splashImageView)
    }
    
    override func configureLayout() {
        splashImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func configureView() {
        super.configureView()
    }

    private func navigateToNextScreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.checkNicknameAndNavigate()
        }
    }
    
    private func checkNicknameAndNavigate() {
        if let nickname = UserDefaults.standard.string(forKey: "nickname"), !nickname.isEmpty {
            showMainViewController()
        } else {
            showNicknameViewController()
        }
    }
    
    private func showMainViewController() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let tabBarController = CustomTabBarController()
        window.rootViewController = tabBarController
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
    
    private func showNicknameViewController() {
        let nicknameVC = NicknameSettingViewController(isEditMode: false)
        nicknameVC.modalPresentationStyle = .fullScreen
        nicknameVC.modalTransitionStyle = .crossDissolve
        present(nicknameVC, animated: true)
    }
}
