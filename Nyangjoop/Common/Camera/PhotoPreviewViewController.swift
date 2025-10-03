//
//  PhotoPreviewViewController.swift
//  Nyangjoop
//
//  Created by Lee on 10/2/25.
//

import UIKit
import SnapKit

protocol PhotoPreviewDelegate: AnyObject {
    func didConfirmPhoto(_ image: UIImage)
    func didCancelPhoto()
}

final class PhotoPreviewViewController: UIViewController {
    
    weak var delegate: PhotoPreviewDelegate?
    private var capturedImage: UIImage
    private var stickers: [PhotoStickerView] = []
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let canvasView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private let bottomControlView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let stickerCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(PhotoStickerCell.self, forCellWithReuseIdentifier: "PhotoStickerCell")
        return collectionView
    }()
    
    private let retakeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다시 찍기", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .clear
        return button
    }()
    
    private let usePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("사진 사용", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .key
        button.layer.cornerRadius = 25
        return button
    }()
    
    private let stickerNames = ["sunglass", "glasses"]
    
    init(image: UIImage) {
        self.capturedImage = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        imageView.image = capturedImage
        stickerCollectionView.delegate = self
        stickerCollectionView.dataSource = self
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(canvasView)
        view.addSubview(bottomControlView)
        bottomControlView.addSubview(stickerCollectionView)
        bottomControlView.addSubview(retakeButton)
        bottomControlView.addSubview(usePhotoButton)
        
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-180)
        }
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(scrollView)
        }
        
        canvasView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
        }
        
        bottomControlView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        stickerCollectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(70)
        }
        
        retakeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(50)
        }
        
        usePhotoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-30)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.width.equalTo(120)
            make.height.equalTo(50)
        }
    }
    
    private func setupActions() {
        retakeButton.addTarget(self, action: #selector(retakeButtonTapped), for: .touchUpInside)
        usePhotoButton.addTarget(self, action: #selector(usePhotoButtonTapped), for: .touchUpInside)
    }
    
    @objc private func retakeButtonTapped() {
        delegate?.didCancelPhoto()
        dismiss(animated: true)
    }
    
    @objc private func usePhotoButtonTapped() {
        let editedImage = renderEditedImage()
        delegate?.didConfirmPhoto(editedImage)
        dismiss(animated: true)
    }
    
    private func addSticker(named: String) {
        guard let image = UIImage(named: named) else { return }
        
        let stickerView = PhotoStickerView(image: image)
        stickerView.frame = CGRect(x: canvasView.bounds.midX - 50,
                                   y: canvasView.bounds.midY - 50,
                                   width: 100,
                                   height: 100)
        
        canvasView.addSubview(stickerView)
        stickers.append(stickerView)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        stickerView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        stickerView.addGestureRecognizer(pinchGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        stickerView.addGestureRecognizer(rotationGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        stickerView.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let stickerView = gesture.view as? PhotoStickerView else { return }
        
        let translation = gesture.translation(in: canvasView)
        stickerView.center = CGPoint(x: stickerView.center.x + translation.x,
                                    y: stickerView.center.y + translation.y)
        gesture.setTranslation(.zero, in: canvasView)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let stickerView = gesture.view as? PhotoStickerView else { return }
        
        stickerView.transform = stickerView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1.0
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let stickerView = gesture.view as? PhotoStickerView else { return }
        
        stickerView.transform = stickerView.transform.rotated(by: gesture.rotation)
        gesture.rotation = 0
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let stickerView = gesture.view as? PhotoStickerView else { return }
        
        if let index = stickers.firstIndex(of: stickerView) {
            stickers.remove(at: index)
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            stickerView.alpha = 0
            stickerView.transform = stickerView.transform.scaledBy(x: 0.1, y: 0.1)
        }) { _ in
            stickerView.removeFromSuperview()
        }
    }
    
    private func renderEditedImage() -> UIImage {
        // 렌더링 전에 모든 스티커의 border 숨기기
        stickers.forEach { $0.hideBorder() }
        
        UIGraphicsBeginImageContextWithOptions(scrollView.bounds.size, false, 0)
        
        scrollView.drawHierarchy(in: scrollView.bounds, afterScreenUpdates: true)
        canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? capturedImage
        UIGraphicsEndImageContext()
        
        // 렌더링 후 스티커의 border 다시 보이기
        stickers.forEach { $0.showBorder() }
        
        return image
    }
}

extension PhotoPreviewViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoStickerCell", for: indexPath) as! PhotoStickerCell
        cell.configure(with: stickerNames[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        addSticker(named: stickerNames[indexPath.item])
    }
}

final class PhotoStickerView: UIView {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    init(image: UIImage) {
        super.init(frame: .zero)
        imageView.image = image
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        isUserInteractionEnabled = true
        showBorder()
    }
    
    func hideBorder() {
        layer.borderWidth = 0
    }
    
    func showBorder() {
        layer.borderWidth = 2
        layer.borderColor = UIColor.key.cgColor
    }
}

final class PhotoStickerCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 12
        
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
    }
    
    func configure(with iconName: String) {
        imageView.image = UIImage(named: iconName)
    }
}
