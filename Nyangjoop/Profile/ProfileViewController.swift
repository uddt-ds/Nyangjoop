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
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView = UIView()
    
    // 프로필 카드
    private let profileCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemOrange
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.crop.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.text = "고양이 친구"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "길냥이를 사랑하는 사람"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()
    
    private let levelLabel: UILabel = {
        let label = UILabel()
        label.text = "Lv. 1"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    // 나의 활동
    private let activityHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "🏆 나의 활동"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let activityCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()
    
    private let registeredCatsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()
    
    private let photoCountStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()
    
    private let visitCountStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()
    
    // 업적
    private let achievementHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "🎖️ 업적"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
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
    
    // 로그아웃 버튼
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemRed.cgColor
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupActivityData()
        setupAchievements()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "프로필"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func configureHierarchy() {
        super.configureHierarchy()
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [profileCardView, activityHeaderLabel, activityCardView,
         achievementHeaderLabel, achievementScrollView, logoutButton].forEach {
            contentView.addSubview($0)
        }
        
        [profileImageView, greetingLabel, descriptionLabel, levelLabel].forEach {
            profileCardView.addSubview($0)
        }
        
        [registeredCatsStackView, photoCountStackView, visitCountStackView].forEach {
            activityCardView.addSubview($0)
        }
        
        achievementScrollView.addSubview(achievementStackView)
    }
    
    override func configureLayout() {
        super.configureLayout()
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // 프로필 카드
        profileCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(120)
        }
        
        profileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(60)
        }
        
        greetingLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalTo(profileImageView.snp.trailing).offset(16)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(greetingLabel.snp.bottom).offset(4)
            make.leading.equalTo(greetingLabel)
        }
        
        levelLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-24)
            make.leading.equalTo(greetingLabel)
        }
        
        // 나의 활동
        activityHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(profileCardView.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(20)
        }
        
        activityCardView.snp.makeConstraints { make in
            make.top.equalTo(activityHeaderLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(100)
        }
        
        registeredCatsStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.centerY.equalToSuperview()
        }
        
        photoCountStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        visitCountStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-30)
            make.centerY.equalToSuperview()
        }
        
        // 업적
        achievementHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(activityCardView.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(20)
        }
        
        achievementScrollView.snp.makeConstraints { make in
            make.top.equalTo(achievementHeaderLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(300)
        }
        
        achievementStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // 로그아웃 버튼
        logoutButton.snp.makeConstraints { make in
            make.top.equalTo(achievementScrollView.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    override func configureView() {
        super.configureView()
        view.backgroundColor = .systemGroupedBackground
        
        logoutButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showLogoutAlert()
            })
            .disposed(by: disposeBag)
    }
    
    private func setupActivityData() {
        // 등록한 고양이
        let catsCountLabel = UILabel()
        catsCountLabel.text = "0"
        catsCountLabel.font = .systemFont(ofSize: 28, weight: .bold)
        catsCountLabel.textColor = .systemGreen
        
        let catsTitleLabel = UILabel()
        catsTitleLabel.text = "등록한 고양이"
        catsTitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        catsTitleLabel.textColor = .secondaryLabel
        
        registeredCatsStackView.addArrangedSubview(catsCountLabel)
        registeredCatsStackView.addArrangedSubview(catsTitleLabel)
        
        // 촬영한 사진
        let photoCountLabel = UILabel()
        photoCountLabel.text = "156"
        photoCountLabel.font = .systemFont(ofSize: 28, weight: .bold)
        photoCountLabel.textColor = .systemBlue
        
        let photoTitleLabel = UILabel()
        photoTitleLabel.text = "촬영한 사진"
        photoTitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        photoTitleLabel.textColor = .secondaryLabel
        
        photoCountStackView.addArrangedSubview(photoCountLabel)
        photoCountStackView.addArrangedSubview(photoTitleLabel)
        
        // 총 방문 횟수
        let visitCountLabel = UILabel()
        visitCountLabel.text = "89"
        visitCountLabel.font = .systemFont(ofSize: 28, weight: .bold)
        visitCountLabel.textColor = .systemOrange
        
        let visitTitleLabel = UILabel()
        visitTitleLabel.text = "총 방문 횟수"
        visitTitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        visitTitleLabel.textColor = .secondaryLabel
        
        visitCountStackView.addArrangedSubview(visitCountLabel)
        visitCountStackView.addArrangedSubview(visitTitleLabel)
    }
    
    private func setupAchievements() {
        let achievements = [
            ("첫 만남", "첫 고양이를 등록하세요", "완료"),
            ("사진작가", "사진 100장 촬영", "완료"),
            ("단골손님", "7일 연속 방문", "완료")
        ]
        
        for achievement in achievements {
            let achievementView = createAchievementView(
                title: achievement.0,
                description: achievement.1,
                status: achievement.2
            )
            achievementStackView.addArrangedSubview(achievementView)
        }
    }
    
    private func createAchievementView(title: String, description: String, status: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        
        let iconView = UIView()
        iconView.backgroundColor = .systemOrange
        iconView.layer.cornerRadius = 20
        
        let iconLabel = UILabel()
        iconLabel.text = "🏅"
        iconLabel.font = .systemFont(ofSize: 20)
        iconLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = .secondaryLabel
        
        let statusLabel = UILabel()
        statusLabel.text = status
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .systemBlue
        
        containerView.addSubview(iconView)
        iconView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descLabel)
        containerView.addSubview(statusLabel)
        
        containerView.snp.makeConstraints { make in
            make.height.equalTo(80)
        }
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        
        iconLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }
        
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
        
        return containerView
    }
    
    private func showLogoutAlert() {
        let alert = UIAlertController(
            title: "로그아웃",
            message: "정말 로그아웃 하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { _ in
            // 로그아웃 로직
            print("로그아웃")
        })
        
        present(alert, animated: true)
    }
}
