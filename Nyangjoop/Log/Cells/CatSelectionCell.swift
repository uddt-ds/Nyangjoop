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
        imageView.layer.cornerRadius = 30  // 60 / 2
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
        view.layer.cornerRadius = 33  // 66 / 2
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 재사용 시 이미지 초기화
        catImageView.image = nil
        catImageView.contentMode = .scaleAspectFill
        nameLabel.text = nil
        selectionBorder.isHidden = true
    }
    
    func configure(with cat: Cat?, isSelected: Bool) {
        // cat이 nil이면 "전체" 표시
        if let cat = cat {
            nameLabel.text = cat.name
            catImageView.contentMode = .scaleAspectFill
            
            // 고양이 이미지 설정
            if let image = UIImage(named: cat.drawImage) {
                catImageView.image = image
            } else {
                catImageView.image = UIImage(systemName: "cat.fill")
                catImageView.tintColor = .systemGray3
            }
        } else {
            // "전체" 셀
            nameLabel.text = "전체"
            catImageView.image = UIImage(systemName: "square.grid.2x2")
            catImageView.tintColor = .systemBlue
            catImageView.contentMode = .scaleAspectFit
        }
        
        // 선택 상태 표시
        selectionBorder.isHidden = !isSelected
        nameLabel.textColor = isSelected ? .systemBlue : .label
        nameLabel.font = isSelected ? .systemFont(ofSize: 12, weight: .bold) : .systemFont(ofSize: 12, weight: .medium)
    }
}
