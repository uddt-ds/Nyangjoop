//
//  CustomTabBarController.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CustomTabBarController: UIViewController {
    private let disposeBag = DisposeBag()

    private var viewControllers: [UIViewController] = []
    private var selectedIndex: Int = 0 {
        didSet {
            updateSelectedViewController()
        }
    }

    private let containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private let customTabBar: CustomTabBar = {
        let tabBar = CustomTabBar()
        return tabBar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupViewControllers()
        configureHierarchy()
        configureLayout()
        bindTabBar()
        updateSelectedViewController()
    }

    private func setupViewControllers() {
        let homeVC = HomeViewController()
        let nav = UINavigationController(rootViewController: homeVC)
        let logVC = LogViewController()

        viewControllers = [nav, logVC]

        viewControllers.forEach { vc in
            addChild(vc)
            vc.didMove(toParent: self)
        }
    }

    private func configureHierarchy() {
        view.addSubview(containerView)
        view.addSubview(customTabBar)
    }

    private func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
         }

         customTabBar.snp.makeConstraints { make in
             make.leading.trailing.equalToSuperview().inset(20)
             make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
             make.height.equalTo(50)
         }
    }

    private func bindTabBar() {
        customTabBar.tabSelected
            .subscribe(onNext: { [weak self] index in
                guard let self else { return }
                switch index {
                case 0:
                    self.selectedIndex = 0
                case 1:
                    self.presentCatRegisterViewController()
                case 2:
                    self.selectedIndex = 1
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    private func updateSelectedViewController() {
        containerView.subviews.forEach { $0.removeFromSuperview() }
        guard selectedIndex < viewControllers.count else { return }

        let selectedVC = viewControllers[selectedIndex]
        containerView.addSubview(selectedVC.view)

        selectedVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let tabIndex = selectedIndex == 0 ? 0 : 2
        customTabBar.selectTab(at: tabIndex)
    }

    private func presentCatRegisterViewController() {
        let catRegisterVC = CatRegisterViewController()
        let nav = UINavigationController(rootViewController: catRegisterVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}
