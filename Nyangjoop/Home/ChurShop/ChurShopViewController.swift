import UIKit
import SnapKit
import Toast

final class ChurShopViewController: BaseViewController {

    private let viewModel = ChurShopViewModel()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .appBg
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()   
        label.text = "츄르 구하기"
        label.font = FontSystem.main.font
        label.textColor = .appTitle
        label.textAlignment = .center
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .appTitle
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ChurShopAdCell.self, forCellWithReuseIdentifier: ChurShopAdCell.identifier)
        collectionView.register(ChurShopItemCell.self, forCellWithReuseIdentifier: ChurShopItemCell.identifier)
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .key
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let shopItems: [(percentage: String?, count: String, price: String?, productID: String?)] = [
        (nil, "x 1", nil, nil),
        ("100%", "x 10", "₩1,000", "com.jean.Nyangjoop.Chur10"),
        ("100%", "x 100", "₩10,000", "com.jean.Nyangjoop.Chur100"),
        ("100%", "x 1000", "₩100,000", "com.jean.Nyangjoop.Chur1000")
    ]

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        viewModel.delegate = self
        viewModel.loadRewardAd()
    }
    
    override func configureHierarchy() {
        super.configureHierarchy()
        
        view.addSubview(containerView)
        
        [titleLabel, closeButton, collectionView, loadingIndicator].forEach {
            containerView.addSubview($0)
        }
    }
    
    override func configureLayout() {
        super.configureLayout()
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(32)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(280)
            make.bottom.equalToSuperview().offset(-24)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .absolute(132)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(132)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = .fixed(16)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) {
            dismiss(animated: true)
        }
    }
    
    private func handleItemSelection(at index: Int) {
        print("[ChurShopViewController] handleItemSelection called with index: \(index)")
        let item = shopItems[index]
        
        if let productID = item.productID {
            print("[ChurShopViewController] Purchasing product: \(productID)")
            viewModel.purchaseProduct(productID: productID)
        } else {
            print("[ChurShopViewController] Showing reward ad")
            if !viewModel.isReady {
                loadingIndicator.startAnimating()
            }
            viewModel.showRewardAd(from: self)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension ChurShopViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: view)
        let isInsideContainer = containerView.frame.contains(location)
        print("[ChurShopViewController] Gesture shouldReceive - isInsideContainer: \(isInsideContainer)")
        return !isInsideContainer
    }
}

extension ChurShopViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("[ChurShopViewController] numberOfItemsInSection: \(shopItems.count)")
        return shopItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("[ChurShopViewController] cellForItemAt: \(indexPath.item)")
        let item = shopItems[indexPath.item]
        
        if indexPath.item == 0 {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ChurShopAdCell.identifier,
                for: indexPath
            ) as? ChurShopAdCell else {
                return UICollectionViewCell()
            }
            cell.configure(isEnabled: viewModel.canShowAd, remainingCount: viewModel.remainingAds)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ChurShopItemCell.identifier,
                for: indexPath
            ) as? ChurShopItemCell else {
                return UICollectionViewCell()
            }
            
            cell.configure(
                percentage: item.percentage,
                number: item.count,
                price: item.price
            )
            return cell
        }
    }
}

extension ChurShopViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("[ChurShopViewController] Cell selected at index: \(indexPath.item)")
        handleItemSelection(at: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        print("[ChurShopViewController] shouldSelectItemAt: \(indexPath.item)")
        return true
    }
}

extension ChurShopViewController: ChurShopViewModelDelegate {
    func showRewardSuccess(churCount: Int) {
        loadingIndicator.stopAnimating()
        showAlert(title: "보상 지급", message: "츄르를 획득했어요! 현재 츄르: \(churCount)개")
    }
    
    func showPurchaseSuccess(churCount: Int) {
        showAlert(title: "구매 완료", message: "츄르를 구매했어요! 현재 츄르: \(churCount)개")
    }

    func showError(message: String) {
        loadingIndicator.stopAnimating()
        showAlert(title: "알림", message: message)
    }
    
    func showToast(message: String) {
        loadingIndicator.stopAnimating()
        view.makeToast(message, duration: 2.0, position: .bottom)
    }
    
    func adDidLoad() {
        loadingIndicator.stopAnimating()
    }
    
    func updateAdCell() {
        collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
    }
}
