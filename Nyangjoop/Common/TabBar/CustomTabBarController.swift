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
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(120)
        }
    }

    private func bindTabBar() {
        customTabBar.tabSelected
            .subscribe(onNext: { [weak self] index in
                guard let self else { return }
                print("탭 선택됨: \(index)")
                switch index {
                case 0:
                    print("홈 화면으로 이동")
                    self.selectedIndex = 0
                case 1:
                    print("등록 모달 표시")
                    self.presentCatRegisterViewController()
                case 2:
                    print("로그 화면으로 이동")
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
    }

    private func presentCatRegisterViewController() {
        print("CatRegisterViewController 생성 시작")
        
        // HomeViewController에 callout 숨기기 알림 전송
        NotificationCenter.default.post(name: NSNotification.Name("HideCallout"), object: nil)
        
        let catRegisterVC = CatRegisterViewController()
        let nav = UINavigationController(rootViewController: catRegisterVC)
        nav.modalPresentationStyle = .pageSheet
        
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        print("모달 present 시작")
        present(nav, animated: true) {
            print("모달 present 완료")
        }
        
        nav.presentationController?.delegate = self
    }
    
    func hideTabBar() {
        customTabBar.isHidden = true
    }
    
    func showTabBar() {
        customTabBar.isHidden = false
    }
}

extension CustomTabBarController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        selectedIndex = 0
        
        if let homeNav = viewControllers.first as? UINavigationController,
           let homeVC = homeNav.viewControllers.first as? HomeViewController {
            homeVC.viewWillAppear(false)
        }
    }
}
