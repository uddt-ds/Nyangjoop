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
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [dateLabel, photoContainerView, memoContainerView, saveButton].forEach {
            contentView.addSubview($0)
        }

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

        photoContainerView.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(20)
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

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

//MARK: Rx Binding
extension LogRecordViewController {
    private func bind() {
        let input = LogRecordViewModel.Input(
            viewDidLoad: .just(()),
            selectedCat: .just(selectedCat),
            photoButtonTapped: photoButton.rx.tap.asObservable(),
            photoSelected: photoSelectedSubject.asObservable(),
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
            message: "기록이 성공적으로 저장되었습니다!",  // 메시지 수정
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let self else { return }
            if self.navigationController != nil {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        })

        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension LogRecordViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage {
            photoSelectedSubject.onNext(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
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
