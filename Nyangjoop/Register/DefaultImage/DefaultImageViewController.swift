//
//  DefaultImageViewController.swift
//  Nyangjoop
//
//  Created by Lee on 9/28/25.
//

import UIKit
import RxSwift
import RxCocoa

protocol DefaultImageDelegate: AnyObject {
    func didSelectDefaultImage(_ image: UIImage, imageName: String)
}

final class DefaultImageViewController: BaseViewController {
    weak var delegate: DefaultImageDelegate?

    private var disposeBag = DisposeBag()

    private let viewModel = DefaultImageViewModel()
    private let imageSelectedSubject = PublishSubject<Int>()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCompositionalLayout())
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsSelection = true
        collectionView.register(DefaultImageCell.self, forCellWithReuseIdentifier: DefaultImageCell.identifier)
        return collectionView
    }()

    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택하기", for: .normal)
        button.backgroundColor = .systemGray4
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.isEnabled = false
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .systemGray
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 15
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        [collectionView, closeButton, selectButton].forEach {
            view.addSubview($0)
        }
    }

    override func configureLayout() {
        super.configureLayout()
        configureBackgroundForCenterModal()
    }

    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { _, _ in

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/4))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(12)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 12
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            return section
        }
    }

    private func configureBackgroundForCenterModal() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 16
        containerView.layer.shadowOpacity = 0.3

        view.addSubview(containerView)
        [collectionView, selectButton].forEach { containerView.addSubview($0) }

        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(350)
            make.height.equalTo(500)
        }

        // 기존 레이아웃을 컨테이너 기준으로 변경
        collectionView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(selectButton.snp.top).offset(-20)
        }

        selectButton.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(50)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-15)
            make.size.equalTo(30)
        }
    }
}

//MARK: Rx binding
extension DefaultImageViewController {
    private func bind() {
        let input = DefaultImageViewModel.Input(
            viewDidLoad: .just(()),
            imageSelected: imageSelectedSubject.asObservable(),
            selectedButtonTapped: selectButton.rx.tap.asObservable())

        let output = viewModel.transform(input)

        output.imageNames
            .drive(with: self) { owner, _ in
                owner.collectionView.reloadData()
            }
            .disposed(by: disposeBag)

        output.selectedIndex
            .drive(with: self) { owner, _ in
                owner.collectionView.reloadData()
            }
            .disposed(by: disposeBag)

        output.isSelectButtonEnabled
            .drive(with: self) { owner, isEnabled in
                owner.selectButton.isEnabled = isEnabled
                owner.selectButton.backgroundColor = isEnabled ? .systemBlue : .systemGray4
            }
            .disposed(by: disposeBag)

        output.selectedImage
            .drive(with: self) { owner, image in
                if let imageName = owner.viewModel.getCurrentSelectedImageName() {
                    owner.delegate?.didSelectDefaultImage(image, imageName: imageName)
                }
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        closeButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}

extension DefaultImageViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        imageSelectedSubject.onNext(indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfImages
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DefaultImageCell.identifier, for: indexPath) as? DefaultImageCell else { return .init() }

        let imageName = viewModel.imageName(at: indexPath.item)
        let isSelected = viewModel.isSelected(at: indexPath.item)
        cell.configure(imageName: imageName, isSelected: isSelected)

        return cell
    }
}
