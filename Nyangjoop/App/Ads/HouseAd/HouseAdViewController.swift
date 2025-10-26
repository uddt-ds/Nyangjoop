import UIKit

final class HouseAdViewController: UIViewController {
    
    private let adView = HouseAdView()
    private var countdownTimer: Timer?
    private var remainingSeconds = 5
    
    var onComplete: ((Bool) -> Void)?
    var onAction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureAd()
        startCountdown()
    }
    
    private func setupUI() {
        view.addSubview(adView)
        
        adView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        adView.onClose = { [weak self] in
            self?.handleClose(didGiveReward: false)
        }
        
        adView.onAction = { [weak self] in
            self?.handleAction()
        }
    }
    
    private func configureAd() {
        let adImage = UIImage(named: "chur")
        
        adView.configure(
            image: adImage,
            title: "광고 제거하고\n츄르 무제한 받기!",
            description: "더 이상 광고를 보지 않고\n언제든 츄르를 받을 수 있어요",
            buttonTitle: "₩3,300 광고 제거하기"
        )
    }
    
    private func startCountdown() {
        adView.updateTimer(seconds: remainingSeconds)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            
            if self.remainingSeconds > 0 {
                self.adView.updateTimer(seconds: self.remainingSeconds)
            } else {
                self.countdownTimer?.invalidate()
                self.giveReward()
            }
        }
    }
    
    private func handleAction() {
        countdownTimer?.invalidate()
        onAction?()
        handleClose(didGiveReward: true)
    }
    
    private func handleClose(didGiveReward: Bool) {
        countdownTimer?.invalidate()
        dismiss(animated: true) { [weak self] in
            self?.onComplete?(didGiveReward)
        }
    }
    
    private func giveReward() {
        adView.enableClose()
        handleClose(didGiveReward: true)
    }
    
    deinit {
        countdownTimer?.invalidate()
    }
}
