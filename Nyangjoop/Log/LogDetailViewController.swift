import UIKit
import SnapKit

final class LogDetailViewController: UIViewController {
    
    private let viewModel: LogDetailViewModel
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 16
        view.layer.shadowOpacity = 0.3
        return view
    }()
    
    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        return stackView
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray
        return button
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 12
        return imageView
    }()
    
    private let catInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()
    
    private let catIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let catNameLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.body.font
        label.textColor = .label
        return label
    }()
    
    private let memoTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont(name: "MemomentKkukkukkR", size: 14) ?? .systemFont(ofSize: 14)
        textView.textColor = .label
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = true
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("수정하기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = .key
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("삭제하기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = .key
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [editButton, deleteButton])
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    init(viewModel: LogDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)
        
        view.addSubview(containerView)
        containerView.addSubview(closeButton)
        containerView.addSubview(containerStackView)
        
        catInfoStackView.addArrangedSubview(catIconImageView)
        catInfoStackView.addArrangedSubview(catNameLabel)
        catNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        catIconImageView.setContentHuggingPriority(.required, for: .horizontal)
        catIconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        containerStackView.addArrangedSubview(imageView)
        containerStackView.addArrangedSubview(catInfoStackView)
        containerStackView.addArrangedSubview(memoTextView)
        containerStackView.addArrangedSubview(buttonStackView)
    }
    
    private func setupConstraints() {
        let hasMemo = !viewModel.memo.isEmpty
        let containerHeight: CGFloat = hasMemo ? 600 : 450
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(containerHeight)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(32)
        }
        
        containerStackView.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        imageView.snp.makeConstraints { make in
            make.height.equalTo(imageView.snp.width)
        }
        
        catInfoStackView.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        
        catIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        if hasMemo {
            memoTextView.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(100)
            }
        }
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        imageView.image = viewModel.logImage
        catIconImageView.image = viewModel.catIcon
        catNameLabel.text = viewModel.catName
        
        if viewModel.memo.isEmpty {
            memoTextView.isHidden = true
        } else {
            memoTextView.text = viewModel.memo
            memoTextView.isHidden = false
        }
    }
    
    @objc private func backgroundTapped() {
        dismiss(animated: true)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func editButtonTapped() {
        viewModel.editLog()
    }
    
    @objc private func deleteButtonTapped() {
        viewModel.deleteLog()
    }
}
