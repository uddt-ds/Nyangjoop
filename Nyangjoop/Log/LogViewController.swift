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
    private var visitLogsCache: [VisitLog] = []

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "기록하기"
        label.font = FontSystem.main.font
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
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(80), heightDimension: .estimated(84))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(80), heightDimension: .estimated(84))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private lazy var logCollectionView: UICollectionView = {
        let layout = WaterfallLayout()
        layout.delegate = self
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 100, right: 10)
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
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "함께 쌓은 추억이 없습니다"
        label.font = FontSystem.body.font
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        bind()
    }
    
    private func setupCollectionView() {
        logCollectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.onNext(())
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        [titleLabel, catSelectionCollectionView, logCollectionView, addLogButton, emptyStateLabel].forEach {
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
            make.height.equalTo(84)
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
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
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

        output.catsWithSelection
            .drive(catSelectionCollectionView.rx.items(
                cellIdentifier: CatSelectionCell.identifier,
                cellType: CatSelectionCell.self
            )) { index, item, cell in
                cell.configure(with: item.cat, isSelected: item.isSelected)
            }
            .disposed(by: disposeBag)

        output.visitLogs
            .drive(with: self) { owner, visitLogs in
                owner.visitLogsCache = visitLogs
                owner.emptyStateLabel.isHidden = !visitLogs.isEmpty
                owner.logCollectionView.isHidden = visitLogs.isEmpty
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
        nav.modalPresentationStyle = .pageSheet
        
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        
        present(nav, animated: true)
    }
}

extension LogViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visitLogsCache.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: LogRecordCell.identifier,
            for: indexPath
        ) as? LogRecordCell else {
            return UICollectionViewCell()
        }
        
        let visitLog = visitLogsCache[indexPath.item]
        let cellWidth = (collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right) / 2
        
        let dummyCell = LogRecordCell()
        let imageHeight = dummyCell.calculateImageHeight(from: visitLog.filePath, targetWidth: cellWidth - 16)
        
        cell.configure(with: visitLog, imageHeight: imageHeight)
        return cell
    }
}

extension LogViewController: WaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath) -> CGFloat {
        let visitLog = visitLogsCache[indexPath.item]
        let cellWidth = (collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right) / 2
        
        let dummyCell = LogRecordCell()
        return dummyCell.calculateHeight(for: visitLog, width: cellWidth - 8)
    }
}
