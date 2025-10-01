//
//  CatInfoView.swift
//  Nyangjoop
//
//  Created by Lee on 10/2/25.
//

import UIKit
import SnapKit

protocol CatInfoViewDelegate: AnyObject {
    func catInfoViewDidTapConfirm()
}

final class CatInfoView: UIView {
    
    weak var delegate: CatInfoViewDelegate?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "고양이등록증"
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 80
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemGray5.cgColor
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private let nameContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    private let genderContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let genderLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    private let daysContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let daysLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("확인", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        addSubview(containerView)
        
        [titleLabel, photoImageView, nameContainerView, genderContainerView, daysContainerView, confirmButton].forEach {
            containerView.addSubview($0)
        }
        
        nameContainerView.addSubview(nameLabel)
        genderContainerView.addSubview(genderLabel)
        daysContainerView.addSubview(daysLabel)
        
        setupLayout()
        setupActions()
    }
    
    private func setupLayout() {
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.size.equalTo(160)
        }
        
        nameContainerView.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        genderContainerView.snp.makeConstraints { make in
            make.top.equalTo(nameContainerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        genderLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        daysContainerView.snp.makeConstraints { make in
            make.top.equalTo(genderContainerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        daysLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(daysContainerView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
    
    private func setupActions() {
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func confirmButtonTapped() {
        delegate?.catInfoViewDidTapConfirm()
    }
    
    @objc private func backgroundTapped() {
        delegate?.catInfoViewDidTapConfirm()
    }
    
    func configure(with cat: Cat) {
        nameLabel.text = cat.name
        
        let genderText: String
        switch cat.gender {
        case 0:
            genderText = "남아"
        case 1:
            genderText = "여아"
        default:
            genderText = "알 수 없음"
        }
        genderLabel.text = "성별: \(genderText)"
        
        if let firstMeetDate = cat.firstVisitDate {
            let days = Calendar.current.dateComponents([.day], from: firstMeetDate, to: Date()).day ?? 0
            daysLabel.text = "만난지 \(days)일"
        } else {
            daysLabel.text = "만난지 0일"
        }
        
        if let imagePath = cat.visitLogs.first?.filePath, !imagePath.isEmpty {
            loadCatImage(from: imagePath)
        } else {
            photoImageView.image = UIImage(named: cat.drawImage)
        }
    }
    
    private func loadCatImage(from imagePath: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsPath.appendingPathComponent(imagePath).path
        
        if let localImage = UIImage(contentsOfFile: fullPath) {
            photoImageView.image = localImage
        } else {
            photoImageView.image = UIImage(systemName: "photo")
        }
    }
}

extension CatInfoView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self
    }
}
