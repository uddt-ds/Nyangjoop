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

    private let viewWillAppearSubject = PublishSubject<Void>()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "기록하기"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        return label
    }()

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
        button.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        button.backgroundColor = .clear
        button.tintColor = .key
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.onNext(())
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        [titleLabel, catSelectionCollectionView, logCollectionView, addLogButton].forEach {
            view.addSubview($0)
        }
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
        }

        catSelectionCollectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }

        logCollectionView.snp.makeConstraints { make in
            make.top.equalTo(catSelectionCollectionView.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }

        addLogButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.top)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(44)
        }
    }

    private func createGridLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = 12
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(0.65)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(spacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 100, trailing: 20)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: Rx binding
extension LogViewController {
    private func bind() {
        let catSelected = catSelectionCollectionView.rx.modelSelected(CatWithSelection.self)
            .map { $0.cat }
            .asObservable()
        
        let input = LogViewModel.Input(
            viewDidLoad: .just(()),
            viewWillAppear: viewWillAppearSubject.asObservable(),
            catSelected: catSelected,
            addLogButtonTapped: addLogButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        // 고양이 선택 CollectionView 바인딩
        output.catsWithSelection
            .drive(catSelectionCollectionView.rx.items(
                cellIdentifier: CatSelectionCell.identifier,
                cellType: CatSelectionCell.self
            )) { index, item, cell in
                cell.configure(with: item.cat, isSelected: item.isSelected)
            }
            .disposed(by: disposeBag)

        // 방문 기록 CollectionView 바인딩
        output.visitLogs
            .drive(logCollectionView.rx.items(
                cellIdentifier: LogRecordCell.identifier,
                cellType: LogRecordCell.self
            )) { index, visitLog, cell in
                cell.configure(with: visitLog)
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
        nav.modalPresentationStyle = .pageSheet
        
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        
        present(nav, animated: true)
    }
}
