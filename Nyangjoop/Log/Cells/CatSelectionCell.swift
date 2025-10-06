//
//  CatSelectionCell.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import UIKit
import SnapKit

final class CatSelectionCell: UICollectionViewCell, IdentifierProtocol {
    
    private let selectionCircle: UIView = {
        let view = UIView()
        view.backgroundColor = .key
        view.layer.cornerRadius = 30
        view.isHidden = true
        return view
    }()
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "catBackground")
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        imageView.layer.masksToBounds = false
        imageView.isHidden = true
        return imageView
    }()
    
    private let catImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.caption.font
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    private let selectionBorder: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 33
        view.isHidden = true
        return view
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
        [selectionBorder, selectionCircle, backgroundImageView, catImageView, nameLabel].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func configureLayout() {
        selectionBorder.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(66)
        }
        
        selectionCircle.snp.makeConstraints { make in
            make.center.equalTo(selectionBorder)
            make.size.equalTo(60)
        }
        
        backgroundImageView.snp.makeConstraints { make in
            make.center.equalTo(selectionBorder)
            make.size.equalTo(60)
        }
        
        catImageView.snp.makeConstraints { make in
            make.center.equalTo(selectionBorder)
            make.size.equalTo(60)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(selectionBorder.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    private func configureView() {
        backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        catImageView.image = nil
        catImageView.contentMode = .scaleAspectFit
        nameLabel.text = nil
        selectionBorder.isHidden = true
        backgroundImageView.isHidden = true
        selectionCircle.isHidden = true
    }
    
    func configure(with cat: Cat?, isSelected: Bool) {
        if let cat = cat {
            nameLabel.text = cat.name
            catImageView.contentMode = .scaleAspectFit
            
            if let image = UIImage(named: cat.drawImage) {
                catImageView.image = image
            } else {
                catImageView.image = UIImage(systemName: "cat.fill")
                catImageView.tintColor = .systemGray3
            }
            
            backgroundImageView.isHidden = !isSelected
            selectionCircle.isHidden = true
        } else {
            nameLabel.text = "전체"
            catImageView.image = .totalCat
            catImageView.tintColor = nil
            catImageView.contentMode = .scaleAspectFit
            backgroundImageView.isHidden = !isSelected
            selectionCircle.isHidden = true
        }
        
        selectionBorder.isHidden = !isSelected
        nameLabel.textColor = isSelected ? .key : .label
        nameLabel.font = FontSystem.caption.font
    }
}
