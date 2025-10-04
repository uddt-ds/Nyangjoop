//
//  CatCalloutView.swift
//  Nyangjoop
//
//  Created by Lee on 10/1/25.
//

import UIKit
import SnapKit

protocol CatCalloutViewDelegate: AnyObject {
    func calloutViewDidTapDirections()
    func calloutViewDidTapInfo()
}

final class CatCalloutView: UIView {
    
    weak var delegate: CatCalloutViewDelegate?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let catNameLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.body.font
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let directionsButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "길찾기"
        config.image = UIImage(systemName: "location.fill")
        config.imagePadding = 4
        config.imagePlacement = .leading
        config.baseBackgroundColor = .retroBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FontSystem.caption.font
            return outgoing
        }
        
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let infoButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "정보"
        config.image = UIImage(systemName: "info.circle.fill")
        config.imagePadding = 4
        config.imagePlacement = .leading
        config.baseBackgroundColor = .retroYellow
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FontSystem.caption.font
            return outgoing
        }
        
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let tailView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
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
        backgroundColor = .clear
        
        addSubview(containerView)
        addSubview(tailView)
        
        [catNameLabel, buttonStackView].forEach { containerView.addSubview($0) }
        [directionsButton, infoButton].forEach { buttonStackView.addArrangedSubview($0) }
        
        setupLayout()
        setupTail()
        setupActions()
    }
    
    private func setupLayout() {
        containerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(90)
        }
        
        catNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(catNameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(40)
        }
        
        tailView.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.equalTo(20)
            make.height.equalTo(12)
            make.bottom.equalToSuperview()
        }
    }
    
    private func setupTail() {
        let tailLayer = CAShapeLayer()
        let tailPath = UIBezierPath()
        
        tailPath.move(to: CGPoint(x: 4, y: 0))
        tailPath.addLine(to: CGPoint(x: 16, y: 0))
        tailPath.addLine(to: CGPoint(x: 10, y: 12))
        tailPath.close()
        
        tailLayer.path = tailPath.cgPath
        tailLayer.fillColor = UIColor.white.cgColor
        
        tailLayer.shadowColor = UIColor.black.cgColor
        tailLayer.shadowOpacity = 0.1
        tailLayer.shadowOffset = CGSize(width: 0, height: 2)
        tailLayer.shadowRadius = 4
        
        tailView.layer.addSublayer(tailLayer)
    }
    
    private func setupActions() {
        directionsButton.addTarget(self, action: #selector(directionsButtonTapped), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
    }
    
    @objc private func directionsButtonTapped() {
        delegate?.calloutViewDidTapDirections()
    }
    
    @objc private func infoButtonTapped() {
        delegate?.calloutViewDidTapInfo()
    }
    
    func configure(with catName: String) {
        catNameLabel.text = catName
    }
}
