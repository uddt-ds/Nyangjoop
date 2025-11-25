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
        label.font = FontSystem.caption.font
        label.textColor = .white
        label.textAlignment = .right
        return label
    }()
    
    private let catInfoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let catIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .appTitle
        return imageView
    }()
    
    private let catNameLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.caption.font
        label.textColor = .appTitle
        label.numberOfLines = 1
        return label
    }()
    
    private let memoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "MemomentKkukkukkR", size: 10) ?? .systemFont(ofSize: 10)
        label.textColor = .appTitle
        label.numberOfLines = 0
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
        
        [imageView, catInfoStackView, memoLabel].forEach {
            containerView.addSubview($0)
        }
        
        [overlayView, dateLabel].forEach {
            imageView.addSubview($0)
        }
        
        [catIconImageView, catNameLabel].forEach {
            catInfoStackView.addArrangedSubview($0)
        }
    }

    private func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(150)
        }
        
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(8)
        }
        
        catInfoStackView.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(24)
        }
        
        catIconImageView.snp.makeConstraints { make in
            make.size.equalTo(24)
        }
        
        memoLabel.snp.makeConstraints { make in
            make.top.equalTo(catInfoStackView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12).priority(.high)
        }
        
        memoLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        memoLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    func configure(with visitLog: VisitLog, imageHeight: CGFloat) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd"
        dateLabel.text = formatter.string(from: visitLog.date)

        loadImage(from: visitLog.filePath)
        
        imageView.snp.updateConstraints { make in
            make.height.equalTo(imageHeight)
        }
        
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
            
            memoLabel.snp.updateConstraints { make in
                make.top.equalTo(catInfoStackView.snp.bottom).offset(8)
                make.bottom.equalToSuperview().inset(12).priority(.high)
            }
        } else {
            memoLabel.text = ""
            memoLabel.isHidden = true
            
            memoLabel.snp.updateConstraints { make in
                make.top.equalTo(catInfoStackView.snp.bottom).offset(0)
                make.bottom.equalToSuperview().inset(8).priority(.high)
            }
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func calculateHeight(for visitLog: VisitLog, width: CGFloat) -> CGFloat {
        let containerPadding: CGFloat = 8
        let imageWidth = width - (containerPadding * 2)
        let imageHeight = calculateImageHeight(from: visitLog.filePath, targetWidth: imageWidth)
        
        let imagePadding: CGFloat = 16
        let catInfoHeight: CGFloat = 24
        let catInfoTopPadding: CGFloat = 8
        
        var totalHeight = imagePadding + imageHeight + catInfoTopPadding + catInfoHeight
        
        if let memo = visitLog.memo, !memo.isEmpty {
            let memoTopPadding: CGFloat = 8
            let containerBottomPadding: CGFloat = 12
            let memoWidth = width - (containerPadding * 2) - 24
            let memoFont = UIFont(name: "MemomentKkukkukkR", size: 10) ?? .systemFont(ofSize: 10)
            let memoHeight = calculateTextHeight(text: memo, width: memoWidth, font: memoFont)
            totalHeight += memoTopPadding + memoHeight + containerBottomPadding
        } else {
            let containerBottomPadding: CGFloat = 8
            totalHeight += containerBottomPadding
        }
        
        return totalHeight + (containerPadding * 2)
    }
    
    private func calculateTextHeight(text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height) + 4
    }
    
    func calculateImageHeight(from filePath: String, targetWidth: CGFloat) -> CGFloat {
        guard !filePath.isEmpty else { return targetWidth * 0.7 }
        
        guard let image = FileManager.loadImageWithCache(fileName: filePath) else {
            return targetWidth * 0.7
        }

        let aspectRatio = image.size.height / image.size.width
        return targetWidth * aspectRatio
    }

    private func loadImage(from filePath: String) {
        guard !filePath.isEmpty else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray4
            return
        }

        if let image = FileManager.loadImageWithCache(fileName: filePath) {
            imageView.image = image
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray4
        }
    }
}
