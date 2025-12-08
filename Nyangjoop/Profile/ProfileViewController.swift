//
//  ProfileViewController.swift
//  Nyangjoop
//
//  Created by Lee on 9/30/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import GoogleMobileAds

final class ProfileViewController: BaseViewController {

    private var bannerHeightConstraint: Constraint?

    private var disposeBag = DisposeBag()
    private let viewModel = ProfileViewModel()
    
    private let viewWillAppearSubject = PublishSubject<Void>()
    private var selectedAchievementType: AchievementType?
    private var allAchievements: [ProfileViewModel.Achievement] = []

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .appBg
        return scrollView
    }()
    
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "프로필"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let greetingCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let greetingStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        return stack
    }()
    
    private let titleBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .key.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()
    
    private let titleIconContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let titleMedalBackgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "medal")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .key
        return imageView
    }()
    
    private let titleIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private let badgeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .key
        return label
    }()
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.sub.font
        label.textColor = .label
        return label
    }()
    
    private let nicknameContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let nicknameStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        let nickname = UserDefaults.standard.nickname
        label.text = "\(nickname)님"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let editNicknameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "applepencil.gen1"), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()
    
    private let activityHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "나의 활동"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let activityCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let catsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()
    
    private let visitsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()
    
    private let achievementsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()
    
    private let catsCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .key
        return label
    }()
    
    private let visitsCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .key
        return label
    }()
    
    private let achievementsCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .key
        return label
    }()
    
    private let achievementHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "업적"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let achievementContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .achievementBg
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let achievementScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private let achievementStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemRed.cgColor
        return button
    }()

    private var bannerView: BannerView!
    private var isBannerLoaded = false

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override func configureHierarchy() {
        // 배너 광고 숨김 처리 (광고 필요 시 주석 해제)
        // if bannerView == nil {
        //     setupBannerView()
        // }

        super.configureHierarchy()
        
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 배너 광고 제외 (광고 필요 시 주석 해제)
        [greetingCardView, activityHeaderLabel, activityCardView,
         achievementHeaderLabel, achievementContainerView/*, logoutButton*/].forEach {
            contentView.addSubview($0)
        }

        greetingCardView.addSubview(greetingStackView)
        
        [greetingLabel, titleBadgeView, nicknameContainerView].forEach {
            greetingStackView.addArrangedSubview($0)
        }
        
        titleBadgeView.addSubview(titleIconContainerView)
        titleBadgeView.addSubview(badgeTitleLabel)
        
        [titleMedalBackgroundImageView, titleIconImageView].forEach {
            titleIconContainerView.addSubview($0)
        }
        
        nicknameContainerView.addSubview(nicknameStackView)
        
        [descriptionLabel, editNicknameButton].forEach {
            nicknameStackView.addArrangedSubview($0)
        }
        
        [catsStackView, visitsStackView, achievementsStackView].forEach {
            activityCardView.addSubview($0)
        }
        
        achievementContainerView.addSubview(achievementScrollView)
        achievementScrollView.addSubview(achievementStackView)
    }
    
    // 배너 광고 로드 로직 미사용 처리 (광고 필요 시 주석 해제)
    /*
    private func setupBannerView() {
        let viewWidth = view.frame.width - 40
        let (banner, isReady) = BannerAdManager.shared.getBannerView(for: self, width: viewWidth)
        bannerView = banner
        bannerView.delegate = self

        if isReady {
            print("[프로필] 미리 로드된 광고 즉시 표시")
            bannerView.alpha = 1
            isBannerLoaded = true
        } else {
            print("[프로필] 광고 로드 대기 중")
            bannerView.alpha = 0
        }
    }
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        configureNavigationBar()
        hideCustomTabBar()
        viewWillAppearSubject.onNext(())
        updateNickname()
        setupEditButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showCustomTabBar()
    }
    
    private func hideCustomTabBar() {
        var currentVC: UIViewController? = self
        while let parent = currentVC?.parent {
            currentVC = parent
            if let tabBarController = parent as? CustomTabBarController {
                tabBarController.hideTabBar()
                return
            }
        }
    }
    
    private func showCustomTabBar() {
        var currentVC: UIViewController? = self
        while let parent = currentVC?.parent {
            currentVC = parent
            if let tabBarController = parent as? CustomTabBarController {
                tabBarController.showTabBar()
                return
            }
        }
    }
    
    private func updateNickname() {
        let nickname = UserDefaults.standard.nickname
        descriptionLabel.text = "\(nickname)님"
    }
    
    override func configureLayout() {
        super.configureLayout()
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        greetingCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        greetingStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-16)
        }

        // 배너 광고 레이아웃 제외 (광고 필요 시 주석 해제)
        // bannerView.snp.makeConstraints { make in
        //     make.top.equalTo(greetingCardView.snp.bottom).offset(10)
        //     make.leading.trailing.equalToSuperview().inset(20)
        //     bannerHeightConstraint = make.height.equalTo(bannerView.frame.height).constraint
        // }

        titleBadgeView.snp.makeConstraints { make in
            make.height.equalTo(28)
        }
        
        titleIconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        
        titleMedalBackgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleIconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(3)
            make.centerX.equalToSuperview()
            make.size.equalTo(8)
        }
        
        badgeTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleIconContainerView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
        
        nicknameStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        editNicknameButton.snp.makeConstraints { make in
            make.size.equalTo(20)
        }
        
        activityHeaderLabel.snp.makeConstraints { make in
            // 배너 광고 제외로 인한 레이아웃 수정
            make.top.equalTo(greetingCardView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        activityCardView.snp.makeConstraints { make in
            make.top.equalTo(activityHeaderLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(120)
        }
        
        catsStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.centerY.equalToSuperview()
        }
        
        visitsStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        achievementsStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-30)
            make.centerY.equalToSuperview()
        }
        
        achievementHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(activityCardView.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(20)
        }
        
        achievementContainerView.snp.makeConstraints { make in
            make.top.equalTo(achievementHeaderLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(300)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        /*
        logoutButton.snp.makeConstraints { make in
            make.top.equalTo(achievementContainerView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-20)
        }
        */
        
        achievementScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        achievementStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        view.backgroundColor = .appBg
        setupActivityViews()
    }

    private func configureNavigationBar() {
        navigationController?.navigationBar.tintColor = .label
    }
    
    private func setupEditButton() {
        editNicknameButton.addTarget(self, action: #selector(editNicknameTapped), for: .touchUpInside)
    }
    
    @objc private func editNicknameTapped() {
        let nicknameVC = NicknameSettingViewController(isEditMode: true)
        nicknameVC.onNicknameUpdated = { [weak self] newNickname in
            self?.updateNickname()
        }
        navigationItem.title = ""
        navigationController?.pushViewController(nicknameVC, animated: true)
    }
    
    private func setupActivityViews() {
        let catsTitleLabel = UILabel()
        catsTitleLabel.text = "등록한 고양이"
        catsTitleLabel.font = .systemFont(ofSize: 13)
        catsTitleLabel.textColor = .secondaryLabel
        
        catsStackView.addArrangedSubview(catsCountLabel)
        catsStackView.addArrangedSubview(catsTitleLabel)
        
        let visitsTitleLabel = UILabel()
        visitsTitleLabel.text = "만난 횟수"
        visitsTitleLabel.font = .systemFont(ofSize: 13)
        visitsTitleLabel.textColor = .secondaryLabel
        
        visitsStackView.addArrangedSubview(visitsCountLabel)
        visitsStackView.addArrangedSubview(visitsTitleLabel)
        
        let achievementsTitleLabel = UILabel()
        achievementsTitleLabel.text = "달성한 업적"
        achievementsTitleLabel.font = .systemFont(ofSize: 13)
        achievementsTitleLabel.textColor = .secondaryLabel
        
        achievementsStackView.addArrangedSubview(achievementsCountLabel)
        achievementsStackView.addArrangedSubview(achievementsTitleLabel)
    }
    
    private func bind() {
        let input = ProfileViewModel.Input(
            viewWillAppear: viewWillAppearSubject.asObservable(),
            viewDidLoad: .just(()),
            logoutTapped: Observable.never()
        )
        
        let output = viewModel.transform(input)
        
        output.registeredCatsCount
            .drive(with: self) { owner, count in
                owner.catsCountLabel.text = "\(count)"
            }
            .disposed(by: disposeBag)
        
        output.visitCount
            .drive(with: self) { owner, count in
                owner.visitsCountLabel.text = "\(count)"
            }
            .disposed(by: disposeBag)
        
        output.achievements
            .drive(with: self) { owner, achievements in
                let completedCount = achievements.filter { $0.isCompleted }.count
                owner.achievementsCountLabel.text = "\(completedCount)"
                owner.allAchievements = achievements
                
                print("=== 업적 디버깅 ===")
                for achievement in achievements {
                    print("\(achievement.title): isCompleted = \(achievement.isCompleted)")
                }
                
                if owner.selectedAchievementType == nil {
                    owner.selectedAchievementType = achievements.filter({ $0.isCompleted }).last?.type
                    print("선택된 업적: \(String(describing: owner.selectedAchievementType?.rawValue))")
                }
                
                owner.updateAchievements(achievements)
                owner.updateTitle()
            }
            .disposed(by: disposeBag)
        
        output.photoCount
            .drive()
            .disposed(by: disposeBag)
        
        output.showLogoutConfirm
            .drive()
            .disposed(by: disposeBag)
        
        output.greetMessage
            .drive(greetingLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    private func updateTitle() {
        guard let selectedType = selectedAchievementType,
              let selected = allAchievements.first(where: { $0.type == selectedType }),
              selected.isCompleted else {
            titleBadgeView.isHidden = true
            return
        }
        
        titleBadgeView.isHidden = false
        badgeTitleLabel.text = selected.title
        titleIconImageView.image = UIImage(named: selected.imageName)
    }
    
    private func updateAchievements(_ achievements: [ProfileViewModel.Achievement]) {
        achievementStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        
        for achievement in achievements {
            let achievementView = AchievementItemView()
            achievementView.delegate = self
            let isSelected = achievement.type == selectedAchievementType
            achievementView.configure(
                title: achievement.title,
                description: achievement.description,
                imageName: achievement.imageName,
                achievementType: achievement.type,
                isCompleted: achievement.isCompleted,
                isSelected: isSelected
            )
            achievementStackView.addArrangedSubview(achievementView)
        }
    }
    
    private func showLogoutAlert() {
        let alert = UIAlertController(
            title: "로그아웃",
            message: "정말 로그아웃 하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { _ in
            print("로그아웃 실행")
        })
        
        present(alert, animated: true)
    }
}

extension ProfileViewController: AchievementItemViewDelegate {
    func achievementItemViewDidTap(_ view: AchievementItemView, achievement: AchievementType) {
        if selectedAchievementType == achievement {
            selectedAchievementType = nil
        } else {
            selectedAchievementType = achievement
        }
        updateAchievements(allAchievements)
        updateTitle()
    }
}

// MARK: - GADBannerViewDelegate (배너 광고 미사용 처리 - 광고 필요 시 주석 해제)
/*
extension ProfileViewController: BannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("배너 광고 로드 성공")
        if !isBannerLoaded {
            isBannerLoaded = true
            UIView.animate(withDuration: 0.3) {
                bannerView.alpha = 1
            }
        }
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("배너 광고 로드 실패: \(error.localizedDescription)")
        bannerView.alpha = 0
    }

    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        print("배너 광고 클릭됨")
    }
}
*/
