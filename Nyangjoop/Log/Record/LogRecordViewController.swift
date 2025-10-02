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
        return scrollView
    }()

    private let contentView = UIView()

    private let dateLabel: UILabel = {
        let label = UILabel()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd"
        label.text = formatter.string(from: Date())
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = .systemGray
        return label
    }()

    private let catSelectionButton: UIButton = {
         let button = UIButton(type: .system)
         button.backgroundColor = .systemGray6
         button.layer.cornerRadius = 12
         button.contentHorizontalAlignment = .left
         button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
         return button
     }()

     private let catNameLabel: UILabel = {
         let label = UILabel()
         label.text = "고양이를 선택하세요"
         label.font = .systemFont(ofSize: 16)
         label.textColor = .systemGray
         return label
     }()

     private let catChevronIcon: UIImageView = {
         let imageView = UIImageView()
         imageView.image = UIImage(systemName: "chevron.right")
         imageView.tintColor = .systemGray3
         imageView.contentMode = .scaleAspectFit
         return imageView
     }()


    private let photoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemGray4.cgColor
        return view
    }()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray5
        imageView.isHidden = true
        return imageView
    }()

    private let photoPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "사진 등록하기"
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .systemGray3
        label.textAlignment = .center
        return label
    }()

    private let photoButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        return button
    }()

    private let memoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var memoTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.isScrollEnabled = false // 자동 높이 조절
        return textView
    }()

    private let memoPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "츄르 준날..."
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemGray3
        return label
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("저장하기", for: .normal)
        button.backgroundColor = .systemGray4
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
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

        [dateLabel, catSelectionButton, photoContainerView, memoContainerView, saveButton].forEach {
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

        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(30)
        }

        catSelectionButton.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(56)
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

        photoContainerView.snp.makeConstraints { make in
            make.top.equalTo(catSelectionButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(250)
        }

        photoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(200)
        }

        photoPlaceholderLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        photoButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        memoContainerView.snp.makeConstraints { make in
            make.top.equalTo(photoContainerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(120)
        }

        memoTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
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

    private func setupNavigationBar() {
        title = "기록 추가"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(closeButtonTapped))

        navigationItem.leftBarButtonItem?.tintColor = .systemGray
    }
    
    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
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
                owner.showSaveSuccessAlert()
            }
            .disposed(by: disposeBag)

        output.errorMessage
            .drive(with: self) { owner, message in
                owner.showErrorAlert(message: message)
            }
            .disposed(by: disposeBag)

        catSelectionButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.showCatSelectionView()
            }
            .disposed(by: disposeBag)
    }
}

extension LogRecordViewController {
    private func showPhotoSelectionActionSheet() {
        let alert = UIAlertController(title: "사진 선택", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
            guard let self else { return }
            self.presentCamera()
        })
        alert.addAction(UIAlertAction(title: "사진 앨범", style: .default) { [weak self] _ in
            guard let self else { return }
            self.presentPhotoLibrary()
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("카메라를 사용할 수 없습니다")
            return
        }

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    private func presentPhotoLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func displaySelectedPhoto(_ image: UIImage) {
        photoImageView.image = image
        photoImageView.isHidden = false
        photoPlaceholderLabel.isHidden = true
    }

    private func updateSaveButton(_ isEnabled: Bool) {
        saveButton.isEnabled = isEnabled
        saveButton.backgroundColor = isEnabled ? .systemBlue : .systemGray4
    }

    private func showSaveSuccessAlert() {
        let alert = UIAlertController(
            title: "등록 완료",
            message: "기록이 성공적으로 저장되었습니다!",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let self else { return }
            if let presentingVC = self.presentingViewController {
                presentingVC.dismiss(animated: true)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        })

        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showCatSelectionView() {
        let catSelectionVC = CatSelectionViewController()
        catSelectionVC.onCatSelected = { [weak self] selectedCat in
            guard let self else { return }
            self.selectedCat = selectedCat
            self.updateCatSelectionUI()
        }

        catSelectionVC.modalPresentationStyle = .pageSheet

        if let sheet = catSelectionVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(catSelectionVC, animated: true)
    }

    private func updateCatSelectionUI() {
        if let cat = selectedCat {
            catNameLabel.text = cat.name
            catNameLabel.textColor = .label
        } else {
            catNameLabel.text = "고양이를 선택하세요"
            catNameLabel.textColor = .systemGray
        }

        selectedCatSubject.onNext(selectedCat)
    }
}

extension LogRecordViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage {
            photoSelectedSubject.onNext(image)
            
            // 메타데이터 추출
            if let imageURL = info[.imageURL] as? URL {
                extractMetadata(from: imageURL)
            } else if let mediaMetadata = info[.mediaMetadata] as? [String: Any] {
                extractMetadataFromDictionary(mediaMetadata)
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func extractMetadata(from url: URL) {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            print("메타데이터를 찾을 수 없습니다")
            return
        }
        
        print("이미지 메타데이터: \(metadata)")
        
        if let gpsData = metadata["{GPS}"] as? [String: Any] {
            extractGPSData(from: gpsData)
        }
    }
    
    private func extractMetadataFromDictionary(_ metadata: [String: Any]) {
        print("메타데이터: \(metadata)")
        
        if let gpsData = metadata["{GPS}"] as? [String: Any] {
            extractGPSData(from: gpsData)
        }
    }
    
    private func extractGPSData(from gpsData: [String: Any]) {
        if let latitude = gpsData["Latitude"] as? Double,
           let longitude = gpsData["Longitude"] as? Double {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            locationSetSubject.onNext(coordinate)
            print("위치 정보: \(latitude), \(longitude)")
        } else {
            print("GPS 데이터를 찾을 수 없습니다")
        }
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
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
