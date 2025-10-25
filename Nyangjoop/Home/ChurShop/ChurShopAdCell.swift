import UIKit
import SnapKit

final class ChurShopAdCell: UICollectionViewCell {
    
    static let identifier = "ChurShopAdCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.key.cgColor
        return view
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = -4
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    
    private let churImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chur")
        return imageView
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.text = "x 1"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .appTitle
        label.textAlignment = .left
        return label
    }()
    
    private let adButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .key
        button.layer.cornerRadius = 8
        button.isUserInteractionEnabled = false
        return button
    }()
    
    private let playIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let multiplierLabel: UILabel = {
        let label = UILabel()
        label.text = "x4"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let adDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "광고 보고 츄르먹기"
        label.font = FontSystem.body.font
        label.textColor = .appTitle
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private let disabledLabel: UILabel = {
        let label = UILabel()
        label.text = "리워드 받기 완료"
        label.font = FontSystem.body.font
        label.textColor = .black
        label.textAlignment = .center
        label.alpha = 1.0
        label.isHidden = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureHierarchy() {
        contentView.addSubview(containerView)
        
        [contentStackView, adDescriptionLabel, adButton, disabledLabel].forEach {
            containerView.addSubview($0)
        }
        
        [churImageView, countLabel].forEach {
            contentStackView.addArrangedSubview($0)
        }
        
        [playIconImageView, multiplierLabel].forEach {
            adButton.addSubview($0)
        }
    }
    
    private func configureLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        contentStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(20)
        }
        
        churImageView.snp.makeConstraints {
            $0.width.equalTo(60)
            $0.height.equalTo(80)
        }
        
        adDescriptionLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.bottom.equalTo(adButton.snp.top).offset(-4)
        }
        
        adButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-8)
            $0.height.equalTo(32)
        }
        
        playIconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        multiplierLabel.snp.makeConstraints {
            $0.leading.equalTo(playIconImageView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
        }
        
        disabledLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    func configure(isEnabled: Bool, remainingCount: Int) {
        multiplierLabel.text = "x\(remainingCount)"
        
        if !isEnabled {
            containerView.alpha = 0.5
            adButton.alpha = 0.6
            disabledLabel.isHidden = false
        } else {
            containerView.alpha = 1.0
            adButton.alpha = 1.0
            disabledLabel.isHidden = true
        }
    }
}
