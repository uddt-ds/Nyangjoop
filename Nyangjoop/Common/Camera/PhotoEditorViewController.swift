//
//  PhotoEditorViewController.swift
//  Nyangjoop
//
//  Created by Lee on 10/2/25.
//

import UIKit
import SnapKit

protocol PhotoEditorDelegate: AnyObject {
    func didFinishEditing(_ image: UIImage)
    func didCancelEditing()
}

final class PhotoEditorViewController: UIViewController {
    
    weak var delegate: PhotoEditorDelegate?
    private let originalImage: UIImage
    private var stickers: [StickerView] = []
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let canvasView: UIView = {
        let view = UIView()
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
        collectionView.register(EditorStickerCell.self, forCellWithReuseIdentifier: "EditorStickerCell")
        return collectionView
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("완료", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 25
        return button
    }()
    
    private let stickerNames = ["sunglass", "glasses"]
    
    init(image: UIImage) {
        self.originalImage = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        imageView.image = originalImage
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
        bottomControlView.addSubview(cancelButton)
        bottomControlView.addSubview(doneButton)
        
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-200)
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
            make.height.equalTo(80)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(50)
        }
        
        doneButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-30)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.width.equalTo(120)
            make.height.equalTo(50)
        }
    }
    
    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.didCancelEditing()
        dismiss(animated: true)
    }
    
    @objc private func doneButtonTapped() {
        let editedImage = renderEditedImage()
        delegate?.didFinishEditing(editedImage)
        dismiss(animated: true)
    }
    
    private func addSticker(named: String) {
        guard let image = UIImage(named: named) else { return }
        
        let stickerView = StickerView(image: image)
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        stickerView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let stickerView = gesture.view as? StickerView else { return }
        
        let translation = gesture.translation(in: canvasView)
        stickerView.center = CGPoint(x: stickerView.center.x + translation.x,
                                    y: stickerView.center.y + translation.y)
        gesture.setTranslation(.zero, in: canvasView)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let stickerView = gesture.view as? StickerView else { return }
        
        stickerView.transform = stickerView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1.0
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let stickerView = gesture.view as? StickerView else { return }
        
        stickerView.transform = stickerView.transform.rotated(by: gesture.rotation)
        gesture.rotation = 0
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let stickerView = gesture.view as? StickerView else { return }
        
        stickers.forEach { $0.isSelected = false }
        stickerView.isSelected = true
    }
    
    private func renderEditedImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: scrollView.bounds.size)
        
        return renderer.image { context in
            scrollView.layer.render(in: context.cgContext)
            canvasView.layer.render(in: context.cgContext)
        }
    }
}

extension PhotoEditorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditorStickerCell", for: indexPath) as! EditorStickerCell
        cell.configure(with: stickerNames[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        addSticker(named: stickerNames[indexPath.item])
    }
}

final class StickerView: UIView {
    
    var isSelected: Bool = false {
        didSet {
            layer.borderWidth = isSelected ? 2 : 0
            layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : nil
        }
    }
    
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
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        isUserInteractionEnabled = true
    }
}

final class EditorStickerCell: UICollectionViewCell {
    
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
