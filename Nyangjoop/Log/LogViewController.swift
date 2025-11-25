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
        setupNotifications()
        bind()
    }
    
    private func setupCollectionView() {
        logCollectionView.dataSource = self
        logCollectionView.delegate = self
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCatRegistered),
            name: NSNotification.Name("CatRegistered"),
            object: nil
        )
    }
    
    @objc private func handleCatRegistered() {
        viewWillAppearSubject.onNext(())
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appBg
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
        
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
        
        let imageHeight: CGFloat

        if let cachedSize = ImageCacheManager.shared.getImageSize(forKey: visitLog.filePath) {
            let aspectRatio = cachedSize.height / cachedSize.width
            imageHeight = (cellWidth - 16) * aspectRatio
        } else {
            let dummyCell = LogRecordCell()
            imageHeight = dummyCell.calculateImageHeight(from: visitLog.filePath, targetWidth: cellWidth - 16)
        }

        cell.configure(with: visitLog, imageHeight: imageHeight)
        return cell
    }
}

extension LogViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let visitLog = visitLogsCache[indexPath.item]
        presentLogDetailViewController(with: visitLog)
    }
    
    private func presentLogDetailViewController(with visitLog: VisitLog) {
        let image = FileManager.loadImage(fileName: visitLog.filePath)
        let catIcon = visitLog.cat?.drawImage.isEmpty == false ? UIImage(named: visitLog.cat?.drawImage ?? "") : nil
        let catName = visitLog.cat?.name ?? ""
        
        let viewModel = LogDetailViewModel(
            logId: visitLog.id.stringValue,
            logImage: image,
            catIcon: catIcon ?? UIImage(systemName: "photo"),
            catName: catName,
            memo: visitLog.memo ?? ""
        )
        viewModel.delegate = self
        
        let detailVC = LogDetailViewController(viewModel: viewModel)
        present(detailVC, animated: true)
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

extension LogViewController: LogDetailViewModelDelegate {
    func logDetailViewModelDidRequestEdit(_ viewModel: LogDetailViewModel) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            let logId = viewModel.getLogId()
            
            if let visitLog = self.visitLogsCache.first(where: { $0.id.stringValue == logId }) {
                let logRecordVC = LogRecordViewController()
                logRecordVC.editingLog = visitLog
                
                let nav = UINavigationController(rootViewController: logRecordVC)
                nav.modalPresentationStyle = .pageSheet
                
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .appBg
                appearance.shadowColor = .clear
                appearance.shadowImage = UIImage()
                
                nav.navigationBar.standardAppearance = appearance
                nav.navigationBar.scrollEdgeAppearance = appearance
                nav.navigationBar.compactAppearance = appearance
                
                if let sheet = nav.sheetPresentationController {
                    sheet.detents = [.large()]
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 24
                }
                
                self.present(nav, animated: true)
            }
        }
    }
    
    func logDetailViewModelDidRequestDelete(_ viewModel: LogDetailViewModel) {
        let logId = viewModel.getLogId()
        
        guard let visitLog = self.visitLogsCache.first(where: { $0.id.stringValue == logId }),
              let cat = visitLog.cat else { return }
        
        if cat.visitLogs.count <= 1 {
            let alert = UIAlertController(
                title: "삭제 불가",
                message: "고양이의 마지막 기록은 삭제할 수 없어요\n고양이를 삭제하려면 마커에서 삭제해주세요",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            presentedViewController?.present(alert, animated: true)
            return
        }
        
        let alert = UIAlertController(
            title: "기록 삭제",
            message: "함께 쌓은 추억이 사라져요\n 정말 삭제하시겠어요?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "아니", style: .cancel))
        alert.addAction(UIAlertAction(title: "응", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            FileManager.deleteImage(fileName: visitLog.filePath)
            try? RealmManager.shared.deleteVisitLog(withId: visitLog.id)
            self.dismiss(animated: true) {
                self.viewWillAppearSubject.onNext(())
            }
        })
        
        presentedViewController?.present(alert, animated: true)
    }
}
