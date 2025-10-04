//
//  LogRecordCell.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import UIKit
import SnapKit

final class LogRecordCell: UICollectionViewCell, IdentifierProtocol {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .right
        return label
    }()
    
    private let infoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let catIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .appTitle
        return imageView
    }()
    
    private let catNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .appTitle
        label.numberOfLines = 1
        return label
    }()
    
    private let memoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .appTitle
        label.numberOfLines = 1
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
        [imageView, overlayView, dateLabel, infoContainerView].forEach {
            containerView.addSubview($0)
        }
        [catIconImageView, catNameLabel, memoLabel].forEach {
            infoContainerView.addSubview($0)
        }
    }

    private func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(containerView.snp.width).multipliedBy(0.7)
        }
        
        overlayView.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.trailing.bottom.equalTo(imageView).inset(8)
        }
        
        infoContainerView.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
        
        catIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(24)
        }
        
        catNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(catIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalTo(catIconImageView)
        }
        
        memoLabel.snp.makeConstraints { make in
            make.leading.equalTo(catIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.top.equalTo(catNameLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    func configure(with visitLog: VisitLog) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd"
        dateLabel.text = formatter.string(from: visitLog.date)

        loadImage(from: visitLog.filePath)
        
        if let cat = visitLog.cat {
            catNameLabel.text = cat.name
            if let catImage = UIImage(named: cat.drawImage) {
                catIconImageView.image = catImage
            } else {
                catIconImageView.image = UIImage(systemName: "cat.fill")
            }
        } else {
            catNameLabel.text = "고양이"
            catIconImageView.image = UIImage(systemName: "cat.fill")
        }
        
        if let memo = visitLog.memo, !memo.isEmpty {
            memoLabel.text = memo
            memoLabel.isHidden = false
        } else {
            memoLabel.text = ""
            memoLabel.isHidden = true
        }
    }

    private func loadImage(from filePath: String) {
        guard !filePath.isEmpty else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray4
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsPath.appending(path: filePath)

        if let image = UIImage(contentsOfFile: fullPath.path()) {
            imageView.image = image
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray4
        }
    }
}
