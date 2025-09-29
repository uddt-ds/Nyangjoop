
//  LogViewController.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.


import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class LogViewController: BaseViewController {
    private var disposeBag = DisposeBag()
    private let viewModel = LogViewModel()

    private let catSelectedSubject = PublishSubject<Cat?>()

    private lazy var catSelectionCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCatSelectionLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsSelection = true
        collectionView.register(CatSelectionCell.self, forCellWithReuseIdentifier: CatSelectionCell.identifier)
        return collectionView
    }()

    private func createCatSelectionLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(80), heightDimension: .absolute(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(80), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private lazy var logCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createGridLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(LogRecordCell.self, forCellWithReuseIdentifier: LogRecordCell.identifier)
        return collectionView
    }()

    private let addLogButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViews()
        bind()
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        [catSelectionCollectionView, logCollectionView, addLogButton].forEach {
            view.addSubview($0)
        }
    }

    override func configureLayout() {

        catSelectionCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }

        logCollectionView.snp.makeConstraints { make in
            make.top.equalTo(catSelectionCollectionView.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }

        addLogButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.size.equalTo(56)
        }
    }

    private func setupCollectionViews() {
        catSelectionCollectionView.delegate = self
        catSelectionCollectionView.dataSource = self

        logCollectionView.delegate = self
        logCollectionView.dataSource = self
    }

    private func createGridLayout() -> UICollectionViewLayout {

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.45))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 100, trailing: 14)
        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: Rx binding
extension LogViewController {
    private func bind() {
        let input = LogViewModel.Input(
            viewDidLoad: .just(()),
            catSelected: catSelectedSubject.asObservable(),
            addLogButtonTapped: addLogButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.cats
            .drive(with: self) { owner, _ in
                owner.catSelectionCollectionView.reloadData()
            }
            .disposed(by: disposeBag)

        output.visitLogs
            .drive(with: self) { owner, _ in
                owner.logCollectionView.reloadData()
            }
            .disposed(by: disposeBag)

        output.presentLogRecord
            .drive(with: self) { owner, selectedCat in
                owner.presentLogRecordViewController(selectedCat: selectedCat)
            }
            .disposed(by: disposeBag)
    }

    private func presentLogRecordViewController(selectedCat: Cat?) {
        let logRecordVC = LogRecordViewController()
        logRecordVC.selectedCat = selectedCat
        let nav = UINavigationController(rootViewController: logRecordVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}

extension LogViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == catSelectionCollectionView {
            return viewModel.numberOfCats
        } else {
            return viewModel.numberOfVisitLogs
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == catSelectionCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CatSelectionCell.identifier, for: indexPath) as? CatSelectionCell else { return .init() }
            let cat = viewModel.cat(at: indexPath.item)
            let isSelected = viewModel.isSelectedCat(at: indexPath.item)
            cell.configure(with: cat, isSelected: isSelected)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LogRecordCell.identifier, for: indexPath) as? LogRecordCell else { return .init() }
            let visitLog = viewModel.visitLog(at: indexPath.item)
            cell.configure(with: visitLog)
            return cell
        }

    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == catSelectionCollectionView {
            let selectedCat = viewModel.cat(at: indexPath.item)
            catSelectedSubject.onNext(selectedCat)
            collectionView.reloadData()
        }
    }
}
