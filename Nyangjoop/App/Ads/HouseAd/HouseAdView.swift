import UIKit
import SnapKit

final class HouseAdView: UIView {
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .churBg
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.main.font
        label.textColor = .appTitle
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.body.font
        label.textColor = .appTitle
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .key
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = FontSystem.main.font
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemGray
        button.backgroundColor = .white
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        return button
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()
    
    var onClose: (() -> Void)?
    var onAction: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .black.withAlphaComponent(0.7)
        
        addSubview(containerView)
        [imageView, titleLabel, descriptionLabel, actionButton, timerLabel].forEach {
            containerView.addSubview($0)
        }
        addSubview(closeButton)
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(30)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(250)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        timerLabel.snp.makeConstraints { make in
            make.top.equalTo(actionButton.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(-10)
            make.trailing.equalTo(containerView).offset(10)
            make.size.equalTo(36)
        }
        
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
    }
    
    func configure(image: UIImage?, title: String, description: String, buttonTitle: String) {
        imageView.image = image
        titleLabel.text = title
        descriptionLabel.text = description
        actionButton.setTitle(buttonTitle, for: .normal)
    }
    
    func updateTimer(seconds: Int) {
        timerLabel.text = "\(seconds)초 후 보상 지급"
    }
    
    func enableClose() {
        closeButton.isHidden = false
    }
    
    @objc private func handleClose() {
        onClose?()
    }
    
    @objc private func handleAction() {
        onAction?()
    }
}
