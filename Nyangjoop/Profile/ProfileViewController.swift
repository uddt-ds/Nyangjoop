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

final class ProfileViewController: BaseViewController {
    
    private var disposeBag = DisposeBag()
    private let viewModel = ProfileViewModel()
    
    private let viewWillAppearSubject = PublishSubject<Void>()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .appBg
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .label
        return button
    }()
    
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
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.text = "반가워요"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        let nickname = UserDefaults.standard.string(forKey: "nickname") ?? "묘험가"
        label.text = "\(nickname)님"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
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
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let achievementOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.85)
        view.layer.cornerRadius = 16
        return view
    }()

    private let comingSoonLabel: UILabel = {
        let label = UILabel()
        label.text = "준비중"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // CustomTabBar 숨기기 - 최상위 ViewController에서 찾기
        hideCustomTabBar()
        viewWillAppearSubject.onNext(())
        updateNickname()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // CustomTabBar 다시 보이기
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
        let nickname = UserDefaults.standard.string(forKey: "nickname") ?? "묘험가"
        descriptionLabel.text = "\(nickname)님"
    }
    
    override func configureHierarchy() {
        super.configureHierarchy()
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [greetingCardView, activityHeaderLabel, activityCardView,
         achievementHeaderLabel, achievementContainerView/*, logoutButton*/].forEach {
            contentView.addSubview($0)
        }
        
        [greetingLabel, descriptionLabel].forEach {
            greetingCardView.addSubview($0)
        }
        
        [catsStackView, visitsStackView, achievementsStackView].forEach {
            activityCardView.addSubview($0)
        }
        
        achievementContainerView.addSubview(achievementScrollView)
        achievementScrollView.addSubview(achievementStackView)
        
        achievementContainerView.addSubview(achievementOverlayView)
        achievementOverlayView.addSubview(comingSoonLabel)
    }
    
    override func configureLayout() {
        super.configureLayout()
        
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(44)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(8)
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
            make.height.equalTo(100)
        }
        
        greetingLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(greetingLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
        }
        
        activityHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(greetingCardView.snp.bottom).offset(32)
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
        
        achievementOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        comingSoonLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        view.backgroundColor = .appBg
        setupActivityViews()
        setupBackButton()
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
    
    private func setupBackButton() {
        backButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        /*
        logoutButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.showLogoutAlert()
            }
            .disposed(by: disposeBag)
        */
    }
    
    private func bind() {
        let input = ProfileViewModel.Input(
            viewWillAppear: viewWillAppearSubject.asObservable(),
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
                owner.updateAchievements(achievements)
            }
            .disposed(by: disposeBag)
        
        output.photoCount
            .drive()
            .disposed(by: disposeBag)
        
        output.showLogoutConfirm
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func updateAchievements(_ achievements: [ProfileViewModel.Achievement]) {
        achievementStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        
        for achievement in achievements {
            let achievementView = createAchievementItemView(
                title: achievement.title,
                description: achievement.description,
                isCompleted: achievement.isCompleted
            )
            achievementStackView.addArrangedSubview(achievementView)
        }
    }
    
    private func createAchievementItemView(title: String, description: String, isCompleted: Bool) -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        
        let checkmarkView = UIImageView()
        checkmarkView.image = UIImage(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
        checkmarkView.tintColor = isCompleted ? .key : .systemGray4
        checkmarkView.contentMode = .scaleAspectFit
        
        view.addSubview(titleLabel)
        view.addSubview(descLabel)
        view.addSubview(checkmarkView)
        
        view.snp.makeConstraints { make in
            make.height.equalTo(80)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(20)
        }
        
        checkmarkView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(24)
        }
        
        return view
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
