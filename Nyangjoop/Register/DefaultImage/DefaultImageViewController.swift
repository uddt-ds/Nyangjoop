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

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCompositionalLayout())
        collectionView.backgroundColor = .clear
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
        button.titleLabel?.font = FontSystem.body.font
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
    }

    override func configureLayout() {
        super.configureLayout()
        configureBackgroundForCenterModal()
    }
    
    override func configureView() {
        view.backgroundColor = .clear
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
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 16
        containerView.layer.shadowOpacity = 0.3

        view.addSubview(containerView)
        [collectionView, closeButton, selectButton].forEach { containerView.addSubview($0) }

        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(350)
            make.height.equalTo(500)
        }

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
            make.leading.equalToSuperview().offset(15)
            make.size.equalTo(30)
        }
    }
}

//MARK: Rx binding
extension DefaultImageViewController {
    private func bind() {
        // CollectionView의 아이템 선택을 Observable로
        let imageSelected = collectionView.rx.itemSelected
            .map { $0.item }
            .asObservable()
        
        let input = DefaultImageViewModel.Input(
            viewDidLoad: .just(()),
            imageSelected: imageSelected,
            selectedButtonTapped: selectButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        // CollectionView에 데이터 바인딩 (Reactive)
        output.imageItems
            .drive(collectionView.rx.items(
                cellIdentifier: DefaultImageCell.identifier,
                cellType: DefaultImageCell.self
            )) { index, item, cell in
                cell.configure(imageName: item.imageName, isSelected: item.isSelected)
            }
            .disposed(by: disposeBag)

        // 선택 버튼 활성화 상태
        output.isSelectButtonEnabled
            .drive(with: self) { owner, isEnabled in
                owner.selectButton.isEnabled = isEnabled
                owner.selectButton.backgroundColor = isEnabled ? .key : .systemGray4
            }
            .disposed(by: disposeBag)

        // 선택 완료 시 delegate 호출 및 화면 닫기
        output.selectedImage
            .drive(with: self) { owner, result in
                owner.delegate?.didSelectDefaultImage(result.image, imageName: result.imageName)
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        // 닫기 버튼
        closeButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}
