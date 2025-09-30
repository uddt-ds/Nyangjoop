//
//  CatRegisterViewController.swift
//  Nyangjoop
//
//  Created by Lee on 9/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import PhotosUI
import CoreLocation

final class CatRegisterViewController: BaseViewController {

    private var disposeBag = DisposeBag()
    private let viewModel = CatRegisterViewModel()
    
    // PhotoPickerManager 사용
    private var photoPickerManager: PhotoPickerManager!
    private let photoWithMetadataSubject = PublishSubject<PhotoWithMetadata>()

    private let locationSetSubject = PublishSubject<CLLocationCoordinate2D>()
    private let characterSelectedSubject = BehaviorSubject<Int>(value: 5)
    private var selectedCoordinate: CLLocationCoordinate2D?
    private var selectedAddress: String?
    private let defaultImageSelectedSubject = PublishSubject<String>()

    private let characters = CatCharacter.allCases

    private let photoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemGray4.cgColor
        return view
    }()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    private let photoPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "사진을 선택해주세요"
        label.textColor = .systemGray2
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()

    private let photoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("사진 선택", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()

    private let defaultImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("기본 이미지 사용", for: .normal)
        button.backgroundColor = .systemGray5
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        return button
    }()

    private let nameHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "이름 *"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()

    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "고양이 이름을 입력해주세요"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        return textField
    }()

    private let genderHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "성별 *"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()

    private let genderSegmentedControl: UISegmentedControl = {
        let items = CatGender.allCases.map { $0.displayName }
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 2 // 기본값: 모름
        return segmentedControl
    }()

    private let characterHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "성격"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()

    private lazy var characterBtnCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCharacterLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false

        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(CharacterCollectionViewCell.self, forCellWithReuseIdentifier: CharacterCollectionViewCell.identifier)
        return collectionView
    }()


    private let locationHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "발견 장소"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.text = "위치 정보를 가져오는 중..."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.numberOfLines = 2
        return label
    }()

    private let locationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("위치 설정", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()

    private let dateHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "만난 날짜"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()

    private let datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.date = Date()
        return datePicker
    }()

    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("등록하기", for: .normal)
        button.backgroundColor = .systemGray4
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupPhotoPickerManager()
        bind()
    }

    override func configureHierarchy() {
        [photoContainerView, defaultImageButton, nameHeaderLabel, nameTextField,
                 genderHeaderLabel, genderSegmentedControl,
                 characterHeaderLabel, characterBtnCollectionView,
                 locationHeaderLabel, locationLabel, locationButton,
                 dateHeaderLabel, datePicker, registerButton].forEach {
                    view.addSubview($0)
                }

        [photoImageView, photoPlaceholderLabel, photoButton].forEach { photoContainerView.addSubview($0)
        }
    }

    override func configureLayout() {
        super.configureLayout()

        photoContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(160)
        }

        photoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(120)
        }

        photoPlaceholderLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        photoButton.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(12)
            make.height.equalTo(32)
            make.width.equalTo(80)
        }

        defaultImageButton.snp.makeConstraints { make in
            make.top.equalTo(photoContainerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }

        nameHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(defaultImageButton.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        nameTextField.snp.makeConstraints { make in
            make.top.equalTo(nameHeaderLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        genderHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        genderSegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(genderHeaderLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(32)
        }

        characterHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(genderSegmentedControl.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        characterBtnCollectionView.snp.makeConstraints { make in
            make.top.equalTo(characterHeaderLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }

        locationHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(characterBtnCollectionView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        locationLabel.snp.makeConstraints { make in
            make.top.equalTo(locationHeaderLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(locationButton.snp.leading).offset(-12)
        }

        locationButton.snp.makeConstraints { make in
            make.centerY.equalTo(locationLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(36)
            make.width.equalTo(80)
        }

        dateHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        datePicker.snp.makeConstraints { make in
            make.top.equalTo(dateHeaderLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
        }

        registerButton.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
    }

    private func setupNavigationBar() {
        title = "고양이 등록"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }
    
    private func setupPhotoPickerManager() {
        photoPickerManager = PhotoPickerManager(presentingViewController: self)
        
        // PhotoPickerManager에서 메타데이터 포함 사진 받기
        photoPickerManager.selectedPhoto
            .subscribe(onNext: { [weak self] photoWithMetadata in
                guard let self = self else { return }
                self.photoWithMetadataSubject.onNext(photoWithMetadata)
            })
            .disposed(by: disposeBag)
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    private func createCharacterLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { _, _ in

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .estimated(80),
                heightDimension: .absolute(32)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .estimated(80),
                heightDimension: .absolute(32)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.orthogonalScrollingBehavior = .continuous

            return section
        }
    }
}

extension CatRegisterViewController {
    private func bind() {
        let input = CatRegisterViewModel.Input(
            viewDidLoad: .just(()),
            photoButtonTapped: photoButton.rx.tap.asObservable(),
            photoWithMetadataSelected: photoWithMetadataSubject.asObservable(),  // 변경
            defaultImageButtonTapped: defaultImageButton.rx.tap.asObservable(),
            defaultImageSelected: defaultImageSelectedSubject.asObservable(),
            nameTextChanged: nameTextField.rx.text.orEmpty.asObservable(),
            genderSelected: genderSegmentedControl.rx.selectedSegmentIndex.asObservable(),
            characterSelected: characterSelectedSubject.asObservable(),
            locationButtonTapped: locationButton.rx.tap.asObservable(),
            locationSet: locationSetSubject.asObservable(),
            dateSelected: datePicker.rx.date.asObservable(),
            registerButtonTapped: registerButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.showPhotoSelection
            .drive(with: self) { owner, _ in
                owner.photoPickerManager.showPhotoSelectionActionSheet()
            }
            .disposed(by: disposeBag)

        output.selectedPhoto
            .drive(with: self) { owner, image in
                owner.displaySelectedPhoto(image)
            }
            .disposed(by: disposeBag)
        
        // 메타데이터에서 추출된 날짜가 있으면 DatePicker에 설정
        output.extractedDate
            .drive(with: self) { owner, date in
                if let date = date {
                    owner.datePicker.date = date
                    print("DatePicker 날짜 설정: \(date)")
                }
            }
            .disposed(by: disposeBag)

        output.locationText
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)

        output.showLocationPicker
            .drive(with: self) { owner, _ in
                owner.showLocationPickerViewController()
            }
            .disposed(by: disposeBag)

        output.isRegisterEnabled
            .drive(with: self) { owner, isEnabled in
                owner.updateRegisterButton(isEnabled)
            }
            .disposed(by: disposeBag)

        output.registrationCompleted
            .drive(with: self) { owner, _ in
                owner.showRegistrationSuccessAlert()
            }
            .disposed(by: disposeBag)

        output.errorMessage
            .drive(with: self) { owner, message in
                owner.showErrorAlert(message: message)
            }
            .disposed(by: disposeBag)

        output.showDefaultImagePicker
            .drive(with: self) { owner, _ in
                owner.showDefaultImagePicker()
            }
            .disposed(by: disposeBag)
    }

}

extension CatRegisterViewController {
    private func displaySelectedPhoto(_ image: UIImage) {
        photoImageView.image = image
        photoImageView.isHidden = false
        photoPlaceholderLabel.isHidden = true
    }

    private func showLocationPickerViewController() {
        let locationPickerVC = LocationPickerViewController()
        locationPickerVC.delegate = self

        let navController = UINavigationController(rootViewController: locationPickerVC)
        present(navController, animated: true)
    }

    private func updateRegisterButton(_ isEnabled: Bool) {
        registerButton.isEnabled = isEnabled
        registerButton.backgroundColor = isEnabled ? .systemBlue : .systemGray4
    }

    private func showRegistrationSuccessAlert() {
        showSuccessAlert(message: "고양이가 성공적으로 등록되었습니다!") { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    private func showDefaultImagePicker() {
        let defaultImageVC = DefaultImageViewController()
        defaultImageVC.delegate = self
        defaultImageVC.modalPresentationStyle = .overFullScreen
        defaultImageVC.modalTransitionStyle = .crossDissolve

        present(defaultImageVC, animated: true)
    }
}

extension CatRegisterViewController: LocationPickerDelegate {
    func didSelectLocation(coordinate: CLLocationCoordinate2D, address: String) {
        selectedCoordinate = coordinate
        selectedAddress = address
        locationLabel.text = address

        locationSetSubject.onNext(coordinate)
    }
}

extension CatRegisterViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return characters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CharacterCollectionViewCell.identifier, for: indexPath) as! CharacterCollectionViewCell

        cell.configure(with: characters[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        characterSelectedSubject.onNext(indexPath.item)
    }
}

extension CatRegisterViewController: DefaultImageDelegate {
    func didSelectDefaultImage(_ image: UIImage, imageName: String) {
        defaultImageSelectedSubject.onNext(imageName)
        
        // 기본 이미지도 PhotoWithMetadata로 변환
        let photoWithMetadata = PhotoWithMetadata(
            image: image,
            location: nil,
            date: nil,
            originalData: nil
        )
        photoWithMetadataSubject.onNext(photoWithMetadata)
        displaySelectedPhoto(image)
    }
}
