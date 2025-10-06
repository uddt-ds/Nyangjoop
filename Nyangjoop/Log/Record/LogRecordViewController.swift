//
//  LogRecordViewController.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import PhotosUI
import CoreLocation

final class LogRecordViewController: BaseViewController {
    var selectedCat: Cat?

    private var disposeBag = DisposeBag()
    private let viewModel = LogRecordViewModel()

    private let photoSelectedSubject = PublishSubject<UIImage>()
    private let locationSetSubject = PublishSubject<CLLocationCoordinate2D>()
    private var selectedCoordinate: CLLocationCoordinate2D?

    private let selectedCatSubject = BehaviorSubject<Cat?>(value: nil)

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .appBg
        return scrollView
    }()

    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "기록 추가"
        label.font = FontSystem.main.font
        label.textColor = .label
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd"
        label.text = formatter.string(from: Date())
        label.font = FontSystem.body.font
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let catHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "고양이 선택 *"
        label.font = FontSystem.body.font
        label.textColor = .label
        return label
    }()

    private let catSelectionButton: UIButton = {
         var config = UIButton.Configuration.plain()
         config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
         config.background.backgroundColor = .white
         config.background.cornerRadius = 16
         config.background.strokeWidth = 1
         config.background.strokeColor = .systemGray5
         
         let button = UIButton(configuration: config)
         button.contentHorizontalAlignment = .left
         return button
     }()

     private let catNameLabel: UILabel = {
         let label = UILabel()
         label.text = "고양이를 선택하세요"
         label.font = FontSystem.body.font
         label.textColor = .systemGray2
         return label
     }()

     private let catChevronIcon: UIImageView = {
         let imageView = UIImageView()
         imageView.image = UIImage(systemName: "chevron.right")
         imageView.tintColor = .systemGray3
         imageView.contentMode = .scaleAspectFit
         return imageView
     }()

    private let photoHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "사진 선택 *"
        label.font = FontSystem.body.font
        label.textColor = .label
        return label
    }()

    private let photoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray6
        imageView.isHidden = true
        return imageView
    }()

    private let photoPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "사진 등록하기"
        label.font = FontSystem.sub.font
        label.textColor = .systemGray3
        label.textAlignment = .center
        return label
    }()

    private let photoButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        return button
    }()
    
    private let memoHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "메모 작성"
        label.font = FontSystem.body.font
        label.textColor = .label
        return label
    }()

    private let memoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()

    private lazy var memoTextView: UITextView = {
        let textView = UITextView()
        textView.font = FontSystem.body.font
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.isScrollEnabled = false
        return textView
    }()

    private let memoPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "메모를 입력하세요"
        label.font = FontSystem.body.font
        label.textColor = .systemGray3
        return label
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("저장하기", for: .normal)
        button.backgroundColor = .systemGray4
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.isEnabled = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setupNavigationBar()
        setupKeyboardDismiss()
        updateCatSelectionUI()
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, dateLabel, catHeaderLabel, catSelectionButton, 
         photoHeaderLabel, photoContainerView, 
         memoHeaderLabel, memoContainerView, saveButton].forEach {
            contentView.addSubview($0)
        }

        [catNameLabel, catChevronIcon].forEach { catSelectionButton.addSubview($0) }

        [photoImageView, photoPlaceholderLabel, photoButton].forEach {
            photoContainerView.addSubview($0)
        }

        [memoTextView, memoPlaceholderLabel].forEach {
            memoContainerView.addSubview($0)
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

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        catHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }

        catSelectionButton.snp.makeConstraints { make in
            make.top.equalTo(catHeaderLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(60)
        }

        catNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        catChevronIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        photoHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(catSelectionButton.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }

        photoContainerView.snp.makeConstraints { make in
            make.top.equalTo(photoHeaderLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(200)
        }

        photoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        photoPlaceholderLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        photoButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        memoHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(photoContainerView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }

        memoContainerView.snp.makeConstraints { make in
            make.top.equalTo(memoHeaderLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(120)
        }

        memoTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        memoPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(21)
            make.trailing.equalToSuperview().offset(-21)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(memoContainerView.snp.bottom).offset(30)
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
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

//MARK: Rx Binding
extension LogRecordViewController {
    private func bind() {
        let input = LogRecordViewModel.Input(
            viewDidLoad: .just(()),
            selectedCat: selectedCatSubject.asObservable(),
            photoButtonTapped: photoButton.rx.tap.asObservable(),
            photoSelected: photoSelectedSubject.asObservable(),
            locationFromPhoto: locationSetSubject.asObservable(),
            memoTextChanged: memoTextView.rx.text.orEmpty.asObservable(),
            saveButtonTapped: saveButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.showPhotoSelection
            .drive(with: self) { owner, _ in
                owner.showPhotoSelectionActionSheet()
            }
            .disposed(by: disposeBag)

        output.selectedPhoto
            .drive(with: self) { owner, image in
                owner.displaySelectedPhoto(image)
            }
            .disposed(by: disposeBag)

        output.isSaveEnabled
            .drive(with: self) { owner, isEnabled in
                owner.updateSaveButton(isEnabled)
            }
            .disposed(by: disposeBag)

        output.saveCompleted
            .drive(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        output.errorMessage
            .drive(with: self) { owner, message in
                owner.showErrorAlert(message: message)
            }
            .disposed(by: disposeBag)

        catSelectionButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.showCatSelectionSheet()
            }
            .disposed(by: disposeBag)
    }
}

extension LogRecordViewController {
    private func displaySelectedPhoto(_ image: UIImage) {
        photoImageView.image = image
        photoImageView.isHidden = false
        photoPlaceholderLabel.isHidden = true
    }

    private func updateSaveButton(_ isEnabled: Bool) {
        saveButton.isEnabled = isEnabled
        saveButton.backgroundColor = isEnabled ? .key : .systemGray4
    }

    private func showPhotoSelectionActionSheet() {
        let alert = UIAlertController(title: "사진 선택", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
            self?.presentCamera()
        })

        alert.addAction(UIAlertAction(title: "앨범에서 선택", style: .default) { [weak self] _ in
            self?.presentPHPicker()
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    private func showCatSelectionSheet() {
        let catSelectionVC = CatSelectionViewController()
        catSelectionVC.onCatSelected = { [weak self] cat in
            self?.selectedCat = cat
            self?.selectedCatSubject.onNext(cat)
            self?.updateCatSelectionUI()
        }
        
        let nav = UINavigationController(rootViewController: catSelectionVC)
        nav.modalPresentationStyle = .pageSheet
        
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        
        present(nav, animated: true)
    }

    private func updateCatSelectionUI() {
        if let cat = selectedCat {
            catNameLabel.text = cat.name
            catNameLabel.textColor = .label
        } else {
            catNameLabel.text = "고양이를 선택하세요"
            catNameLabel.textColor = .systemGray2
        }
    }

    private func presentCamera() {
        let customCamera = CustomCameraViewController()
        customCamera.delegate = self
        customCamera.modalPresentationStyle = .fullScreen
        present(customCamera, animated: false)
    }

    private func presentPHPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension LogRecordViewController: CustomCameraDelegate {
    func didCaptureImage(_ image: UIImage) {
        photoSelectedSubject.onNext(image)
    }
    
    func didRequestRetake() {
        // 재촬영 요청 시 처리
    }
}

extension LogRecordViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            DispatchQueue.main.async {
                if let image = object as? UIImage {
                    guard let self else { return }
                    self.photoSelectedSubject.onNext(image)
                }
            }
        }
    }
}

extension LogRecordViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        memoPlaceholderLabel.isHidden = !textView.text.isEmpty
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        memoPlaceholderLabel.isHidden = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        memoPlaceholderLabel.isHidden = !textView.text.isEmpty
    }
}
