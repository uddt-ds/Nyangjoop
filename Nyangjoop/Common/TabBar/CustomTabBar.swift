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
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        return button
    }()
    
    private let menuIconView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private var semiCircleLayer: CAShapeLayer?

    // 첫 번째 서브 버튼 (Home - 왼쪽)
    private let homeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        button.setImage(UIImage(systemName: "house.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .retroRed
        button.layer.cornerRadius = 28
        button.alpha = 0
        button.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        return button
    }()

    // 두 번째 서브 버튼 (Register - 상단) - + 아이콘
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .retroRed
        button.layer.cornerRadius = 28
        button.alpha = 0
        button.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        return button
    }()

    // 세 번째 서브 버튼 (Log - 오른쪽)
    private let logButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        button.setImage(UIImage(systemName: "pencil.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .retroRed
        button.layer.cornerRadius = 28
        button.alpha = 0
        button.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
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
            make.center.equalToSuperview()
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
        shapeLayer.fillColor = UIColor.retroRed.cgColor
        shapeLayer.strokeColor = UIColor.clear.cgColor
        
        // 그림자 추가
        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0, height: -2)
        shapeLayer.shadowRadius = 8
        shapeLayer.shadowOpacity = 0.3
        
        mainButton.layer.insertSublayer(shapeLayer, at: 0)
        semiCircleLayer = shapeLayer
    }
    
    private func createMenuIcon() {
        menuIconView.layer.sublayers?.removeAll()
        
        layoutIfNeeded()
        
        let width = menuIconView.bounds.width
        let height = menuIconView.bounds.height

        guard width > 0, height > 0 else { return }
        
        let lineWidth: CGFloat = 3
        let lineSpacing: CGFloat = 5
        
        for i in 0..<3 {
            let line = CAShapeLayer()
            let path = UIBezierPath()
            let y = CGFloat(i) * (lineWidth + lineSpacing)
            
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
            
            line.path = path.cgPath
            line.strokeColor = UIColor.white.cgColor
            line.lineWidth = lineWidth
            line.lineCap = .round
            
            menuIconView.layer.addSublayer(line)
        }
        
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
