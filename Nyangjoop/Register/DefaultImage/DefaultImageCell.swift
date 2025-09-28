//
//  DefaultImageCell.swift
//  Nyangjoop
//
//  Created by Lee on 9/28/25.
//

import UIKit

final class DefaultImageCell: UICollectionViewCell, IdentifierProtocol {
    private let imageView: UIImageView = {
         let imageView = UIImageView()
         imageView.contentMode = .scaleAspectFill
         imageView.clipsToBounds = true
         imageView.layer.cornerRadius = 12
         imageView.backgroundColor = .systemGray6
         return imageView
     }()

     private let selectionOverlay: UIView = {
         let view = UIView()
         view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
         view.layer.cornerRadius = 12
         view.isHidden = true
         return view
     }()

     private let checkmarkImageView: UIImageView = {
         let imageView = UIImageView()
         imageView.image = UIImage(systemName: "checkmark.circle.fill")
         imageView.tintColor = .systemBlue
         imageView.backgroundColor = .white
         imageView.layer.cornerRadius = 12
         imageView.isHidden = true
         return imageView
     }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func configureHierarchy() {
        [imageView, selectionOverlay, checkmarkImageView].forEach {
            contentView.addSubview($0)
        }
    }

    private func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        selectionOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        checkmarkImageView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
            make.size.equalTo(24)
        }
    }

    private func configureView() {
        contentView.backgroundColor = .white
    }

    func configure(imageName: String, isSelected: Bool) {
        if let image = UIImage(named: imageName) {
            imageView.image = image
        } else {
            imageView.image = UIImage(systemName: "cat.fill")
            imageView.tintColor = .systemGray3
        }

        selectionOverlay.isHidden = !isSelected
        checkmarkImageView.isHidden = !isSelected

        layer.borderWidth = isSelected ? 2 : 0
        layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
        layer.cornerRadius = 12
    }

}
