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
    func catInfoViewDidTapEdit(for cat: Cat)
}

final class CatInfoView: UIView {
    
    weak var delegate: CatInfoViewDelegate?
    private var currentCat: Cat?
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "catIdCard")
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "고양이 등록증"
        label.font = FontSystem.main.font
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    private let photoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemGray4.cgColor
        return view
    }()
    
    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private let characterLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.main.font
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    private let genderStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let genderTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "성별: "
        label.font = FontSystem.body.font
        label.textColor = .label
        return label
    }()
    
    private let genderValueLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.body.font
        label.textColor = .label
        return label
    }()
    
    private let daysStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let daysTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "만난지"
        label.font = FontSystem.body.font
        label.textColor = .label
        return label
    }()
    
    private let daysValueLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.body.font
        label.textColor = .label
        return label
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("확 인", for: .normal)
        button.titleLabel?.font = FontSystem.sub.font
        button.backgroundColor = .clear
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("수 정", for: .normal)
        button.titleLabel?.font = FontSystem.sub.font
        button.backgroundColor = .clear
        button.setTitleColor(.label, for: .normal)
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
        
        addSubview(backgroundImageView)
        
        [titleLabel, photoContainerView, characterLabel, genderStackView, daysStackView, editButton, confirmButton].forEach {
            backgroundImageView.addSubview($0)
        }
        
        photoContainerView.addSubview(photoImageView)
        
        [genderTitleLabel, genderValueLabel].forEach {
            genderStackView.addArrangedSubview($0)
        }
        
        [daysTitleLabel, daysValueLabel].forEach {
            daysStackView.addArrangedSubview($0)
        }
        
        setupLayout()
        setupActions()
    }
    
    private func setupLayout() {
        backgroundImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(340)
            make.height.equalTo(540)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(160)
            make.centerX.equalToSuperview()
        }
        
        photoContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(180)
        }
        
        photoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        characterLabel.snp.makeConstraints { make in
            make.top.equalTo(photoContainerView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
        
        genderStackView.snp.makeConstraints { make in
            make.top.equalTo(characterLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        
        daysStackView.snp.makeConstraints { make in
            make.top.equalTo(genderStackView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        
        editButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-10)
            make.trailing.equalTo(backgroundImageView.snp.centerX).offset(-10)
            make.height.equalTo(44)
            make.width.equalTo(80)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-10)
            make.leading.equalTo(backgroundImageView.snp.centerX).offset(10)
            make.height.equalTo(44)
            make.width.equalTo(80)
        }
    }
    
    private func setupActions() {
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func confirmButtonTapped() {
        animateDismiss()
    }
    
    @objc private func editButtonTapped() {
        if let cat = currentCat {
            delegate?.catInfoViewDidTapEdit(for: cat)
        }
        animateDismiss()
    }
    
    @objc private func backgroundTapped() {
        animateDismiss()
    }
    
    private func animateDismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundImageView.transform = CGAffineTransform(translationX: 0, y: -self.bounds.height)
            self.alpha = 0
        }) { _ in
            self.delegate?.catInfoViewDidTapConfirm()
        }
    }
    
    func configure(with cat: Cat) {
        currentCat = cat
        characterLabel.text = cat.name
        
        let genderText: String
        switch cat.gender {
        case 0:
            genderText = "남아"
        case 1:
            genderText = "여아"
        default:
            genderText = "모름"
        }
        genderValueLabel.text = genderText
        
        if let firstMeetDate = cat.firstVisitDate {
            let days = Calendar.current.dateComponents([.day], from: firstMeetDate, to: Date()).day ?? 0
            daysValueLabel.text = "D+\(days)일째"
        } else {
            daysValueLabel.text = "D+0일째"
        }
        
        if let imagePath = cat.visitLogs.first?.filePath, !imagePath.isEmpty {
            loadCatImage(from: imagePath)
        } else {
            photoImageView.image = UIImage(named: cat.drawImage)
        }
        
        animateIn()
    }
    
    private func animateIn() {
        alpha = 0
        backgroundImageView.transform = CGAffineTransform(translationX: 0, y: -bounds.height)
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.backgroundImageView.transform = .identity
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
