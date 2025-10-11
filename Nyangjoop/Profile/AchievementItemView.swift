import UIKit
import SnapKit

protocol AchievementItemViewDelegate: AnyObject {
    func achievementItemViewDidTap(_ view: AchievementItemView, achievement: AchievementType)
}

final class AchievementItemView: UIView {
    
    weak var delegate: AchievementItemViewDelegate?
    private var achievementType: AchievementType?
    private var isUnlocked: Bool = false
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let iconContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let medalBackgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "medal")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5.withAlphaComponent(0.5)
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func viewTapped() {
        guard isUnlocked, let type = achievementType else { return }
        delegate?.achievementItemViewDidTap(self, achievement: type)
    }
    
    private func configureHierarchy() {
        addSubview(containerView)
        
        [iconContainerView, titleLabel, descriptionLabel, checkmarkImageView].forEach {
            containerView.addSubview($0)
        }
        
        containerView.addSubview(overlayView)
        
        [medalBackgroundImageView, iconImageView].forEach {
            iconContainerView.addSubview($0)
        }
    }
    
    private func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(80)
        }
        
        iconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(50)
        }
        
        medalBackgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(9)
            make.size.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalTo(iconContainerView.snp.trailing).offset(12)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconContainerView.snp.trailing).offset(12)
        }
        
        checkmarkImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(24)
        }
        
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configure(title: String, description: String, imageName: String, achievementType: AchievementType, isCompleted: Bool, isSelected: Bool) {
        self.achievementType = achievementType
        self.isUnlocked = isCompleted
        
        print("[AchievementItemView] \(title) - isCompleted: \(isCompleted), isSelected: \(isSelected)")
        
        titleLabel.text = title
        descriptionLabel.text = description
        iconImageView.image = UIImage(named: imageName)
        
        isUserInteractionEnabled = isCompleted
        overlayView.isHidden = isCompleted
        
        titleLabel.textColor = isCompleted ? .label : .systemGray3
        descriptionLabel.textColor = isCompleted ? .secondaryLabel : .systemGray4
        
        medalBackgroundImageView.tintColor = isCompleted ? .key : .systemGray4
        iconImageView.tintColor = isCompleted ? .white : .systemGray5
        
        if isSelected {
            checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
            checkmarkImageView.tintColor = .key
        } else if isCompleted {
            checkmarkImageView.image = UIImage(systemName: "circle")
            checkmarkImageView.tintColor = .systemGray4
        } else {
            checkmarkImageView.image = UIImage(systemName: "circle")
            checkmarkImageView.tintColor = .systemGray4
        }
    }
}
