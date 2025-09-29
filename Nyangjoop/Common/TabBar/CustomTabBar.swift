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

    private var selectedIndex: Int = 0 {
        didSet {
            updateButtonStates()
        }
    }

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 25
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.15
        return view
    }()

    private let homeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "house.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.tag = 0
        return button
    }()

    private let centerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.app"), for: .normal)
        button.tintColor = .systemGray
        button.tag = 1
        return button
    }()

    private let logButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
        button.tintColor = .systemGray
        button.tag = 2
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        configureActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func configureHierarchy() {
        addSubview(containerView)
        [homeButton, centerButton, logButton].forEach {
            containerView.addSubview($0)
        }
    }

    private func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        homeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }

        centerButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }

        logButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-30)
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }
    }

    private func configureActions() {
        homeButton.rx.tap
            .map { 0 }
            .subscribe { [weak self] index in
                guard let self else { return }
                self.selectedIndex = index
                self.tabSelectedSubject.onNext(index)
            }
            .disposed(by: disposeBag)

        centerButton.rx.tap
            .map { 1 }
            .subscribe { [weak self] index in
                guard let self else { return }
                self.tabSelectedSubject.onNext(index)
            }
            .disposed(by: disposeBag)

        logButton.rx.tap
            .map { 2 }
            .subscribe { [weak self] index in
                guard let self else { return }
                self.selectedIndex = index
                self.tabSelectedSubject.onNext(index)
            }
            .disposed(by: disposeBag)
    }

    private func updateButtonStates() {
        homeButton.tintColor = selectedIndex == 0 ? .systemBlue : .systemGray
        centerButton.tintColor = .systemGray
        logButton.tintColor = selectedIndex == 2 ? .systemBlue : .systemGray
    }

    func selectTab(at index: Int) {
        guard index != 1 else { return }
        selectedIndex = index
    }
}

