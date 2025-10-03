//
//  CharacterCollectionViewCell.swift
//  Nyangjoop
//
//  Created by Lee on 9/27/25.
//

import UIKit
import SnapKit

final class CharacterCollectionViewCell: UICollectionViewCell, IdentifierProtocol {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupUI() {
        contentView.addSubview(titleLabel)

        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 13
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.appTitle.cgColor

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }

        updateAppearance()
    }

    func configure(with character: CatCharacter) {
        titleLabel.text = character.displayName
    }
}

extension CharacterCollectionViewCell {
    private func updateAppearance() {
        if isSelected {
            contentView.layer.borderColor = UIColor.key.cgColor
            contentView.layer.borderWidth = 2
            titleLabel.textColor = .appTitle
        } else {
            contentView.layer.borderColor = UIColor.appTitle.cgColor
            contentView.layer.borderWidth = 1
            titleLabel.textColor = .appTitle
        }
    }
}
