//
//  CatSelectionViewController.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CatSelectionViewController: BaseViewController {
    var onCatSelected: ((Cat) -> Void)?

    private var disposeBag = DisposeBag()
    private let realmManager = RealmManager.shared
    private var cats: [Cat] = []

    private lazy var collectionView: UICollectionView = {
         let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
         collectionView.backgroundColor = .systemBackground
         collectionView.register(CatCardCell.self, forCellWithReuseIdentifier: CatCardCell.identifier)
         collectionView.delegate = self
         collectionView.dataSource = self
         return collectionView
     }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "등록된 고양이가 없습니다"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        loadCats()
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        [collectionView, emptyLabel].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        super.configureLayout()

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func configureView() {
        super.configureView()
    }

    private func setupNavigationBar() {
        title = "고양이 선택"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .systemGray
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .estimated(200)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200))

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(16)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func loadCats() {
        cats = Array(realmManager.fetchAllCats())

        emptyLabel.isHidden = !cats.isEmpty
        collectionView.reloadData()
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

extension CatSelectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cats.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CatCardCell.identifier, for: indexPath) as? CatCardCell else { return .init() }
        let cat = cats[indexPath.item]
        cell.configure(with: cat)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCat = cats[indexPath.item]
        onCatSelected?(selectedCat)
        dismiss(animated: true)
    }
}
