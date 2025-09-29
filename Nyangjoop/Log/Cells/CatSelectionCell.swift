//
//  CatSelectionCell.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import UIKit
import SnapKit

final class CatSelectionCell: UICollectionViewCell, IdentifierProtocol {
    
    private let catImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    private let selectionBorder: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.systemBlue.cgColor
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutSubviews()
        configureHierarchy()
        configureLayout()
        configureView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        catImageView.layer.cornerRadius = catImageView.frame.width / 2
        selectionBorder.layer.cornerRadius = selectionBorder.frame.width / 2
    }
    
    private func configureHierarchy() {
        [selectionBorder, catImageView, nameLabel].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func configureLayout() {
        selectionBorder.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(66)
        }
        
        catImageView.snp.makeConstraints { make in
            make.center.equalTo(selectionBorder)
            make.size.equalTo(60)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(selectionBorder.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(14)
        }
    }
    
    private func configureView() {
        backgroundColor = .clear
    }
    
    func configure(with cat: Cat, isSelected: Bool) {
        nameLabel.text = cat.name
        
        // 고양이 이미지 설정
        if let image = UIImage(named: cat.drawImage) {
            catImageView.image = image
        } else {
            catImageView.image = UIImage(systemName: "cat.fill")
            catImageView.tintColor = .systemGray3
        }
        
        // 선택 상태 표시
        selectionBorder.isHidden = !isSelected
        nameLabel.textColor = isSelected ? .systemBlue : .label
        nameLabel.font = isSelected ? .systemFont(ofSize: 12, weight: .bold) : .systemFont(ofSize: 12, weight: .medium)
    }
}
