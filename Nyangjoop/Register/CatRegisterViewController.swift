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
    private lazy var viewModel: CatRegisterViewModel = {
        let vm = CatRegisterViewModel()
        if isEditMode {
            vm.isEditMode = true
            vm.editingCat = editingCat
        }
        return vm
    }()
    
    private let isEditMode: Bool
    private let editingCat: Cat?
    private var hasConfigured: Bool = false
    var onCatUpdated: (() -> Void)?

    init(isEditMode: Bool = false, editingCat: Cat? = nil) {
        self.isEditMode = isEditMode
        self.editingCat = editingCat
        super.init(nibName: nil, bundle: nil)
        print("[CatRegisterVC] init - isEditMode: \(isEditMode), editingCat: \(String(describing: editingCat?.name))")
    }
    
    private var photoPickerManager: PhotoPickerManager!
    private let photoWithMetadataSubject = PublishSubject<PhotoWithMetadata>()

    private let locationSetSubject = PublishSubject<CLLocationCoordinate2D>()
    private let characterSelectedSubject = BehaviorSubject<Int>(value: 0)
    private let genderSelectedSubject = BehaviorSubject<Int?>(value: nil)
    private var selectedCoordinate: CLLocationCoordinate2D?
    private var selectedAddress: String?
    private let defaultImageSelectedSubject = PublishSubject<String>()

    private let characters = CatCharacter.allCases

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .appBg
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .appBg
        return view
    }()

    private let imageSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "이미지 *"
        label.font = FontSystem.main.font
        label.textColor = .appTitle
        return label
    }()
    
    private let imageSectionDescLabel: UILabel = {
        let label = UILabel()
        label.text = "실제 사진과 지도 표시용 아이콘을 함께 선택해주세요"
        label.font = FontSystem.caption.font
        label.textColor = .appTitle
        label.numberOfLines = 0
        return label
    }()
    
    private let imageSelectionContainerView = UIView()

    private let photoSectionView = UIView()
    
    private let photoLabel: UILabel = {
        let label = UILabel()
        label.text = "실제 사진"
        label.font = FontSystem.caption.font
        label.textColor = .appTitle
        label.textAlignment = .center
        return label
    }()

    private let photoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.appTitle.cgColor
        return view
    }()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray6
        imageView.isHidden = true
        return imageView
    }()

    private let photoPlaceholderStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()
    
    private let photoIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "camera.fill")
        imageView.tintColor = .appTitle
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let photoPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "사진 선택"
        label.textColor = .appTitle
        label.font = FontSystem.caption.font
        label.textAlignment = .center
        return label
    }()
    
    private let photoLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .key
        return indicator
    }()

    private let defaultImageSectionView = UIView()
    
    private let defaultImageLabel: UILabel = {
        let label = UILabel()
        label.text = "지도 표시 아이콘"
        label.font = FontSystem.caption.font
        label.textColor = .appTitle
        label.textAlignment = .center
        return label
    }()

    private let defaultImageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.appTitle.cgColor
        return view
    }()

    private let defaultImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.isHidden = true
        return imageView
    }()

    private let defaultImagePlaceholderStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()
    
    private let defaultImageIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "cat.fill")
        imageView.tintColor = .appTitle
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let defaultImagePlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "아이콘 선택"
        label.textColor = .appTitle
        label.font = FontSystem.caption.font
        label.textAlignment = .center
        return label
    }()

    private let nameHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "이름 *"
        label.font = FontSystem.main.font
        label.textColor = .appTitle
        return label
    }()

    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "고양이 이름을 입력해주세요"
        textField.font = FontSystem.body.font
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.returnKeyType = .done
        textField.delegate = self
        return textField
    }()
    
    private let nameUnderlineView: UIView = {
        let view = UIView()
        view.backgroundColor = .appTitle
        return view
    }()

    private let genderHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "성별 *"
        label.font = FontSystem.main.font
        label.textColor = .appTitle
        return label
    }()
    
    private let genderButtonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 24
        return stack
    }()
    
    private let maleButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "남아"
        config.baseForegroundColor = .appTitle
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FontSystem.body.font
            return outgoing
        }
        
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.key.cgColor
        button.tag = 0
        return button
    }()
    
    private let femaleButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "여아"
        config.baseForegroundColor = .appTitle
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FontSystem.body.font
            return outgoing
        }
        
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.key.cgColor
        button.tag = 1
        return button
    }()
    
    private let unknownGenderButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "모름"
        config.baseForegroundColor = .appTitle
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FontSystem.body.font
            return outgoing
        }
        
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.key.cgColor
        button.tag = 2
        return button
    }()

    private let characterHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "성격"
        label.font = FontSystem.main.font
        label.textColor = .appTitle
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
        label.text = "발견 장소 *"
        label.font = FontSystem.main.font
        label.textColor = .appTitle
        return label
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.text = "위치 정보를 가져오는 중..."
        label.font = FontSystem.caption.font
        label.textColor = .appTitle
        label.numberOfLines = 2
        return label
    }()

    private let locationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("위치 설정", for: .normal)
        button.backgroundColor = .key
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 8
        return button
    }()

    private let dateHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "만난 날짜 *"
        label.font = FontSystem.main.font
        label.textColor = .appTitle
        return label
    }()

    private let datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.date = Date()
        datePicker.backgroundColor = .white
        datePicker.maximumDate = .now
        datePicker.layer.cornerRadius = 8
        return datePicker
    }()

    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("등록하기", for: .normal)
        button.backgroundColor = .systemGray4
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("[CatRegisterVC] viewDidLoad - isEditMode: \(isEditMode)")
        
        setupPhotoPickerManager()
        setupGestures()
        setupGenderButtons()
        setupKeyboardHandling()
        
        if !isEditMode {
            selectDefaultCharacter()
            selectGenderButton(unknownGenderButton)
            genderSelectedSubject.onNext(2)
        }

        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !hasConfigured {
            setupNavigationBar()
            
            if isEditMode {
                print("[CatRegisterVC] viewWillAppear - 수정 모드 UI 설정")
                configureForEditMode()
            }
            
            hasConfigured = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [imageSectionLabel, imageSectionDescLabel, imageSelectionContainerView,
         nameHeaderLabel, nameTextField, nameUnderlineView,
         genderHeaderLabel, genderButtonsStackView,
         characterHeaderLabel, characterBtnCollectionView,
         locationHeaderLabel, locationLabel, locationButton,
         dateHeaderLabel, datePicker, registerButton].forEach {
            contentView.addSubview($0)
        }

        [photoSectionView, defaultImageSectionView].forEach {
            imageSelectionContainerView.addSubview($0)
        }
        
        [photoLabel, photoContainerView].forEach {
            photoSectionView.addSubview($0)
        }
        
        [photoImageView, photoPlaceholderStackView, photoLoadingIndicator].forEach { 
            photoContainerView.addSubview($0)
        }
        
        [photoIconView, photoPlaceholderLabel].forEach {
            photoPlaceholderStackView.addArrangedSubview($0)
        }

        [defaultImageLabel, defaultImageContainerView].forEach {
            defaultImageSectionView.addSubview($0)
        }
        
        [defaultImageView, defaultImagePlaceholderStackView].forEach {
            defaultImageContainerView.addSubview($0)
        }
        
        [defaultImageIconView, defaultImagePlaceholderLabel].forEach {
            defaultImagePlaceholderStackView.addArrangedSubview($0)
        }
        
        [maleButton, femaleButton, unknownGenderButton].forEach {
            genderButtonsStackView.addArrangedSubview($0)
        }
    }

    override func configureLayout() {
        super.configureLayout()

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        imageSectionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        imageSectionDescLabel.snp.makeConstraints { make in
            make.top.equalTo(imageSectionLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        imageSelectionContainerView.snp.makeConstraints { make in
            make.top.equalTo(imageSectionDescLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(160)
        }
        
        photoSectionView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(imageSelectionContainerView.snp.centerX).offset(-6)
        }
        
        photoLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(18)
        }
        
        photoContainerView.snp.makeConstraints { make in
            make.top.equalTo(photoLabel.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }

        photoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        photoPlaceholderStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        photoIconView.snp.makeConstraints { make in
            make.size.equalTo(32)
        }
        
        photoLoadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        defaultImageSectionView.snp.makeConstraints { make in
            make.leading.equalTo(imageSelectionContainerView.snp.centerX).offset(6)
            make.trailing.top.bottom.equalToSuperview()
        }
        
        defaultImageLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(18)
        }

        defaultImageContainerView.snp.makeConstraints { make in
            make.top.equalTo(defaultImageLabel.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }

        defaultImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(70)
        }

        defaultImagePlaceholderStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        defaultImageIconView.snp.makeConstraints { make in
            make.size.equalTo(32)
        }

        nameHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(imageSelectionContainerView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(60)
        }

        nameTextField.snp.makeConstraints { make in
            make.centerY.equalTo(nameHeaderLabel)
            make.leading.equalTo(nameHeaderLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
        
        nameUnderlineView.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom)
            make.leading.equalTo(nameTextField)
            make.trailing.equalTo(nameTextField)
            make.height.equalTo(1)
        }

        genderHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(nameUnderlineView.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(60)
        }
        
        genderButtonsStackView.snp.makeConstraints { make in
            make.centerY.equalTo(genderHeaderLabel)
            make.leading.equalTo(genderHeaderLabel.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.height.equalTo(44)
        }

        characterHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(genderButtonsStackView.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(60)
        }

        characterBtnCollectionView.snp.makeConstraints { make in
            make.centerY.equalTo(characterHeaderLabel)
            make.leading.equalTo(characterHeaderLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(39)
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
            make.height.equalTo(36)
        }

        registerButton.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    override func configureView() {
        super.configureView()
        view.backgroundColor = .appBg
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .appBg
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        let titleLabel = UILabel()
        titleLabel.text = isEditMode ? "고양이 수정" : "고양이 등록"
        titleLabel.font = FontSystem.main.font
        titleLabel.textColor = .label
        
        let containerView = UIView()
        containerView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview()
        }
        
        let leftBarButtonItem = UIBarButtonItem(customView: containerView)
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeButtonTapped))
        navigationItem.rightBarButtonItem = closeButton
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    private func setupPhotoPickerManager() {
        photoPickerManager = PhotoPickerManager(presentingViewController: self)
        
        photoPickerManager.selectedPhoto
            .subscribe(onNext: { [weak self] photoWithMetadata in
                guard let self = self else { return }
                self.photoWithMetadataSubject.onNext(photoWithMetadata)
            })
            .disposed(by: disposeBag)
        
        photoPickerManager.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.showPhotoLoadingIndicator()
                } else {
                    self.hidePhotoLoadingIndicator()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupGestures() {
        let photoTapGesture = UITapGestureRecognizer(target: self, action: #selector(photoContainerTapped))
        photoContainerView.addGestureRecognizer(photoTapGesture)
        photoContainerView.isUserInteractionEnabled = true
        
        let defaultImageTapGesture = UITapGestureRecognizer(target: self, action: #selector(defaultImageContainerTapped))
        defaultImageContainerView.addGestureRecognizer(defaultImageTapGesture)
        defaultImageContainerView.isUserInteractionEnabled = true
    }
    
    private func setupGenderButtons() {
        maleButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.selectGenderButton(owner.maleButton)
                owner.genderSelectedSubject.onNext(0)
            }
            .disposed(by: disposeBag)
        
        femaleButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.selectGenderButton(owner.femaleButton)
                owner.genderSelectedSubject.onNext(1)
            }
            .disposed(by: disposeBag)
        
        unknownGenderButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.selectGenderButton(owner.unknownGenderButton)
                owner.genderSelectedSubject.onNext(2)
            }
            .disposed(by: disposeBag)
    }
    
    private func selectGenderButton(_ selectedButton: UIButton) {
        [maleButton, femaleButton, unknownGenderButton].forEach { button in
            if button == selectedButton {
                button.layer.borderWidth = 2
            } else {
                button.layer.borderWidth = 0
            }
        }
    }
    
    private func configureForEditMode() {
        guard let cat = editingCat else { return }
        
        // 기존 위치 정보 로드
        viewModel.loadInitialLocation()
        
        nameTextField.text = cat.name
        // nameTextField의 text가 설정되었으므로 rx 이벤트 수동 발생
        nameTextField.sendActions(for: .editingChanged)
        
        switch cat.gender {
        case 0:
            selectGenderButton(maleButton)
            genderSelectedSubject.onNext(0)
        case 1:
            selectGenderButton(femaleButton)
            genderSelectedSubject.onNext(1)
        default:
            selectGenderButton(unknownGenderButton)
            genderSelectedSubject.onNext(2)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let character = cat.character {
                let indexPath = IndexPath(item: character, section: 0)
                self.characterBtnCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.characterSelectedSubject.onNext(character)
            }
        }
        
        // ViewModel에서 위치 설정을 처리하므로 여기서는 좌표만 저장
        selectedCoordinate = CLLocationCoordinate2D(latitude: cat.lat, longitude: cat.lon)
        
        if let firstVisitDate = cat.firstVisitDate {
            datePicker.date = firstVisitDate
        }
        
        if let imagePath = cat.visitLogs.first?.filePath, !imagePath.isEmpty {
            loadCatImage(from: imagePath)
        }
        
        if let drawImage = UIImage(named: cat.drawImage) {
            displaySelectedDefaultImage(drawImage)
            defaultImageSelectedSubject.onNext(cat.drawImage)
        }
        
        registerButton.setTitle("수정하기", for: .normal)
    }
    
    private func loadCatImage(from imagePath: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsPath.appendingPathComponent(imagePath).path
        
        if let localImage = UIImage(contentsOfFile: fullPath) {
            displaySelectedPhoto(localImage)
        }
    }
    
    private func selectDefaultCharacter() {
        DispatchQueue.main.async { [weak self] in
            let indexPath = IndexPath(item: 0, section: 0)
            self?.characterBtnCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
        
        if nameTextField.isFirstResponder {
            let textFieldFrame = nameTextField.convert(nameTextField.bounds, to: scrollView)
            scrollView.scrollRectToVisible(textFieldFrame, animated: true)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func photoContainerTapped() {
        photoPickerManager.showPhotoSelectionActionSheet()
    }
    
    @objc private func defaultImageContainerTapped() {
        showDefaultImagePicker()
    }

    private func createCharacterLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { _, _ in

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .estimated(80),
                heightDimension: .absolute(39)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .estimated(80),
                heightDimension: .absolute(39)
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
            photoWithMetadataSelected: photoWithMetadataSubject.asObservable(),
            defaultImageSelected: defaultImageSelectedSubject.asObservable(),
            nameTextChanged: nameTextField.rx.text.orEmpty
                .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
                .asObservable(),
            genderSelected: genderSelectedSubject.compactMap { $0 }.asObservable(),
            characterSelected: characterSelectedSubject.asObservable(),
            locationButtonTapped: locationButton.rx.tap.asObservable(),
            locationSet: locationSetSubject.asObservable(),
            dateSelected: datePicker.rx.date.asObservable(),
            registerButtonTapped: registerButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.selectedPhoto
            .drive(with: self) { owner, image in
                owner.displaySelectedPhoto(image)
            }
            .disposed(by: disposeBag)
        
        output.selectedDefaultImage
            .drive(with: self) { owner, image in
                owner.displaySelectedDefaultImage(image)
            }
            .disposed(by: disposeBag)
        
        output.extractedDate
            .drive(with: self) { owner, date in
                if let date = date {
                    owner.datePicker.date = date
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
            .drive(with: self) { owner, message in
                owner.showSuccessAlert(message: message) {
                    if !owner.isEditMode {
                        AdTriggerService.shared.incrementRegistrationCount()
                    }
                    
                    AdTriggerService.shared.checkAndShowAdIfNeeded(from: owner) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("CatRegistered"),
                            object: nil
                        )

                        DispatchQueue.main.async {
                            owner.dismiss(animated: true)
                        }
                    }
                }
            }
            .disposed(by: disposeBag)

        output.errorMessage
            .drive(with: self) { owner, message in
                owner.showErrorAlert(message: message)
            }
            .disposed(by: disposeBag)
    }

}

extension CatRegisterViewController {
    private func reverseGeocodeLocation(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                self.locationLabel.text = "위치 정보를 가져올 수 없습니다"
                return
            }
            
            if let placemark = placemarks?.first {
                var addressComponents: [String] = []
                
                if let administrativeArea = placemark.administrativeArea {
                    addressComponents.append(administrativeArea)
                }
                if let locality = placemark.locality {
                    addressComponents.append(locality)
                }
                if let thoroughfare = placemark.thoroughfare {
                    addressComponents.append(thoroughfare)
                }
                if let subThoroughfare = placemark.subThoroughfare {
                    addressComponents.append(subThoroughfare)
                }
                
                let address = addressComponents.joined(separator: " ")
                self.locationLabel.text = address
                self.selectedAddress = address
            }
        }
    }
    
    private func displaySelectedPhoto(_ image: UIImage) {
        photoImageView.image = image
        photoImageView.isHidden = false
        photoPlaceholderStackView.isHidden = true
        
        UIView.animate(withDuration: 0.2) {
            self.photoContainerView.layer.borderColor = UIColor.key.cgColor
            self.photoContainerView.layer.borderWidth = 2
        }
    }
    
    private func showPhotoLoadingIndicator() {
        photoPlaceholderStackView.isHidden = true
        photoLoadingIndicator.startAnimating()
        photoContainerView.isUserInteractionEnabled = false
    }
    
    private func hidePhotoLoadingIndicator() {
        photoLoadingIndicator.stopAnimating()
        photoContainerView.isUserInteractionEnabled = true
        
        if photoImageView.image == nil {
            photoPlaceholderStackView.isHidden = false
        }
    }
    
    private func displaySelectedDefaultImage(_ image: UIImage) {
        defaultImageView.image = image
        defaultImageView.isHidden = false
        defaultImagePlaceholderStackView.isHidden = true
        defaultImageContainerView.layer.borderColor = UIColor.key.cgColor
        defaultImageContainerView.layer.borderWidth = 2
    }

    private func showLocationPickerViewController() {
        let locationPickerVC = LocationPickerViewController()
        locationPickerVC.delegate = self

        let navController = UINavigationController(rootViewController: locationPickerVC)
        present(navController, animated: true)
    }

    private func updateRegisterButton(_ isEnabled: Bool) {
        registerButton.isEnabled = isEnabled
        registerButton.backgroundColor = isEnabled ? .key : .systemGray4
    }

    private func showRegistrationSuccessAlert(message: String) {
        showSuccessAlert(message: message) { [weak self] in
            NotificationCenter.default.post(name: NSNotification.Name("CatRegistered"), object: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.dismiss(animated: true)
            }
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
        displaySelectedDefaultImage(image)
    }
}

extension CatRegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
