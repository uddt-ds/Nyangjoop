//
//  CatCardCell.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import UIKit

final class CatCardCell: UICollectionViewCell, IdentifierProtocol {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func configureHierarchy() {
        contentView.addSubview(containerView)

        [photoImageView, nameLabel].forEach {
            containerView.addSubview($0)
        }
    }

    private func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        photoImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(photoImageView.snp.width)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    func configure(with cat: Cat) {
        nameLabel.text = cat.name

        if cat.name == "전체" {
            photoImageView.image = UIImage(systemName: "square.grid.2x2")
            photoImageView.tintColor = .systemBlue
            photoImageView.contentMode = .scaleAspectFit
            photoImageView.backgroundColor = isSelected ? .systemBlue.withAlphaComponent(0.1) : .systemGray4
        } else {
            if let displayImage = cat.getDisplayImage(forGalleryMode: false) {
                photoImageView.image = displayImage
                photoImageView.contentMode = .scaleAspectFill
                photoImageView.tintColor = nil
                photoImageView.backgroundColor = .systemGray5
            } else {
                photoImageView.image = UIImage(systemName: "cat.fill")
                photoImageView.contentMode = .scaleAspectFit
                photoImageView.tintColor = .systemGray3
                photoImageView.backgroundColor = .systemGray6
            }

            if isSelected {
                photoImageView.layer.borderColor = UIColor.systemBlue.cgColor
                nameLabel.textColor = .systemBlue
                nameLabel.font = .boldSystemFont(ofSize: 12)
            } else {
                photoImageView.layer.borderColor = UIColor.clear.cgColor
                nameLabel.textColor = .label
                nameLabel.font = .systemFont(ofSize: 12)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        nameLabel.text = nil
        photoImageView.layer.borderColor = UIColor.clear.cgColor
    }
}
