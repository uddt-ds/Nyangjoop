import UIKit
import SnapKit

final class AdRemovalCell: UICollectionViewCell {
    
    static let identifier = "AdRemovalCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.key.cgColor
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "speaker.slash.fill")
        imageView.tintColor = .appTitle
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "광고 제거"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .key
        label.textAlignment = .center
        return label
    }()
    
    private let purchasedLabel: UILabel = {
        let label = UILabel()
        label.text = "구매완료"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .systemGreen
        label.textAlignment = .center
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
        [iconImageView, titleLabel, priceLabel, purchasedLabel].forEach {
            containerView.addSubview($0)
        }
    }
    
    private func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        priceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
        
        purchasedLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    
    func configure(price: String?, isPurchased: Bool) {
        if isPurchased {
            priceLabel.isHidden = true
            purchasedLabel.isHidden = false
            containerView.alpha = 0.6
        } else {
            priceLabel.text = price
            priceLabel.isHidden = false
            purchasedLabel.isHidden = true
            containerView.alpha = 1.0
        }
    }
}
