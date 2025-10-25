import UIKit
import SnapKit

final class ChurShopItemCell: UICollectionViewCell {
    
    static let identifier = "ChurShopItemCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.key.cgColor
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .appTitle
        label.textAlignment = .center
        return label
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
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .black
        label.textAlignment = .left
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .key
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
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
        
        [percentageLabel, contentStackView, priceLabel].forEach {
            containerView.addSubview($0)
        }
        
        [churImageView, numberLabel].forEach {
            contentStackView.addArrangedSubview($0)
        }
    }
    
    private func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        percentageLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(12)
        }
        
        contentStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        churImageView.snp.makeConstraints {
            $0.width.equalTo(60)
            $0.height.equalTo(80)
        }
        
        priceLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-12)
        }
    }
    
    func configure(percentage: String?, number: String, price: String?) {
        percentageLabel.text = percentage
        percentageLabel.isHidden = percentage == nil
        
        numberLabel.text = number
        
        priceLabel.text = price
        priceLabel.isHidden = price == nil
    }
}
