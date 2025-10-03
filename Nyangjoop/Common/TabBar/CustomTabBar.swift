//
//  CustomTabBar.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CustomTabBar: UIView {

    var tabSelected: Observable<Int> {
        return tabSelectedSubject.asObservable()
    }

    private let tabSelectedSubject = PublishSubject<Int>()
    private let disposeBag = DisposeBag()
    
    private var isMenuExpanded = false
    private var isAnimating = false

    // 중앙 메인 버튼 (발바닥) - 반원 모양
    private let mainButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        return button
    }()
    
    private let menuIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .hamburger
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private var semiCircleLayer: CAShapeLayer?

    // 첫 번째 서브 버튼 (Home - 왼쪽)
    private let homeButton: UIButton = {
        let resizedImage = UIImage.home.resize(to: CGSize(width: 40, height: 40))
        let button = UIButton()
        button.setImage(resizedImage, for: .normal)
        button.backgroundColor = .key
        button.layer.cornerRadius = 28
        button.alpha = 0
        button.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        return button
    }()

    // 두 번째 서브 버튼 (Register - 상단) - + 아이콘
    private let registerButton: UIButton = {
        let resizedImage = UIImage.addCat.resize(to: CGSize(width: 40, height: 40))
        let button = UIButton()
        button.setImage(resizedImage, for: .normal)
        button.backgroundColor = .key
        button.layer.cornerRadius = 28
        button.alpha = 0
        button.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        return button
    }()

    // 세 번째 서브 버튼 (Log - 오른쪽)
    private let logButton: UIButton = {
        let resizedImage = UIImage.pencil.resize(to: CGSize(width: 40, height: 40))
        let button = UIButton()
        button.setImage(resizedImage, for: .normal)
        button.backgroundColor = .key
        button.layer.cornerRadius = 28
        button.alpha = 0
        button.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        configureActions()
        
        DispatchQueue.main.async { [weak self] in
            self?.createMenuIcon()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if view == self {
            return nil
        }
        
        return view
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        createSemiCircleShape()
        createMenuIcon()
    }

    private func configureHierarchy() {
        [mainButton, homeButton, registerButton, logButton].forEach {
            addSubview($0)
        }
        mainButton.addSubview(menuIconView)
    }

    private func configureLayout() {
        // 메인 버튼 (중앙 하단) - 반원, 크기 증가
        mainButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(140)
            make.height.equalTo(70)
        }
        
        // 햄버거 아이콘
        menuIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
            make.width.equalTo(30)
            make.height.equalTo(22)
        }

        // 홈 버튼 (왼쪽 상단)
        homeButton.snp.makeConstraints { make in
            make.trailing.equalTo(mainButton.snp.leading).offset(10)
            make.bottom.equalTo(mainButton.snp.top).offset(20)
            make.size.equalTo(56)
        }

        // 등록 버튼 (중앙 상단)
        registerButton.snp.makeConstraints { make in
            make.centerX.equalTo(mainButton)
            make.bottom.equalTo(mainButton.snp.top).offset(-5)
            make.size.equalTo(56)
        }

        // 로그 버튼 (오른쪽 상단)
        logButton.snp.makeConstraints { make in
            make.leading.equalTo(mainButton.snp.trailing).offset(-10)
            make.bottom.equalTo(mainButton.snp.top).offset(20)
            make.size.equalTo(56)
        }
    }
    
    private func createSemiCircleShape() {
        semiCircleLayer?.removeFromSuperlayer()
        
        let width = mainButton.bounds.width
        let height = mainButton.bounds.height
        
        guard width > 0, height > 0 else { return }
        
        // 반원 Path: 위쪽만 보이는 반달 모양
        let path = UIBezierPath()
        
        // 왼쪽 아래 시작
        path.move(to: CGPoint(x: 0, y: height))
        
        // 왼쪽 → 위 → 오른쪽으로 둥근 호
        path.addArc(
            withCenter: CGPoint(x: width / 2, y: height),
            radius: width / 2,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        // 오른쪽 아래로
        path.addLine(to: CGPoint(x: width, y: height))
        path.close()
        
        // CAShapeLayer 생성하고 색상 채우기
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.key.cgColor
        shapeLayer.strokeColor = UIColor.clear.cgColor
        
        mainButton.layer.insertSublayer(shapeLayer, at: 0)
        semiCircleLayer = shapeLayer
    }
    
    private func createMenuIcon() {
        layoutIfNeeded()
    }
    
    private func hideMenuIcon() {
        UIView.animate(withDuration: 0.2) {
            self.menuIconView.alpha = 0
        }
    }
    
    private func showMenuIcon() {
        UIView.animate(withDuration: 0.2) {
            self.menuIconView.alpha = 1
        }
    }

    private func configureActions() {
        mainButton.rx.tap
            .subscribe(with: self) { owner, _ in
                guard !owner.isAnimating else { return }
                owner.toggleMenu()
            }
            .disposed(by: disposeBag)

        homeButton.rx.tap
            .subscribe(with: self) { owner, _ in
                guard !owner.isAnimating else { return }
                owner.tabSelectedSubject.onNext(0)
            }
            .disposed(by: disposeBag)

        registerButton.rx.tap
            .subscribe(with: self) { owner, _ in
                guard !owner.isAnimating else { return }
                owner.closeMenuAndSelectTab(1)
            }
            .disposed(by: disposeBag)

        logButton.rx.tap
            .subscribe(with: self) { owner, _ in
                guard !owner.isAnimating else { return }
                owner.tabSelectedSubject.onNext(2)
            }
            .disposed(by: disposeBag)
    }

    private func closeMenuAndSelectTab(_ index: Int) {
        guard isMenuExpanded else {
            tabSelectedSubject.onNext(index)
            return
        }
        
        isAnimating = true
        hideSubButtons { [weak self] in
            guard let self else { return }
            self.showMenuIcon()
            self.isMenuExpanded = false
            self.isAnimating = false
            self.tabSelectedSubject.onNext(index)
        }
    }
    
    private func toggleMenu() {
        guard !isAnimating else { return }
        
        isMenuExpanded.toggle()
        isAnimating = true

        if isMenuExpanded {
            hideMenuIcon()
            showSubButtons()
        } else {
            showMenuIcon()
            hideSubButtons(completion: nil)
        }
    }

    private func showSubButtons() {
        let buttons = [homeButton, registerButton, logButton]
        
        for (index, button) in buttons.enumerated() {
            let delay = Double(index) * 0.08
            let isLastButton = index == buttons.count - 1
            
            UIView.animate(
                withDuration: 0.5,
                delay: delay,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.8,
                options: .curveEaseOut,
                animations: {
                    button.alpha = 1
                    button.transform = .identity
                },
                completion: { [weak self] _ in
                    if isLastButton {
                        self?.isAnimating = false
                    }
                }
            )
        }
    }

    private func hideSubButtons(completion: (() -> Void)?) {
        let buttons = [homeButton, registerButton, logButton]
        var completedCount = 0
        
        for button in buttons.reversed() {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: .curveEaseIn,
                animations: {
                    button.alpha = 0
                    button.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                },
                completion: { _ in
                    completedCount += 1
                    if completedCount == buttons.count {
                        self.isAnimating = false
                        completion?()
                    }
                }
            )
        }
    }
}
