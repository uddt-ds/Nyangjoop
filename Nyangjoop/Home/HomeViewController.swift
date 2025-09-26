//
//  HomeViewController.swift
//  Nyangjoop
//
//  Created by Lee on 9/26/25.
//

import UIKit
import SnapKit
import MapKit
import RxSwift
import RxCocoa

final class HomeViewController: BaseViewController {

    private var disposeBag = DisposeBag()

    private let viewModel = HomeViewModel()

    private var isMenuExpanded = false

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .none
        return mapView
    }()

    private let profileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .systemBlue
        return button
    }()

    private let menuToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .systemGray
        return button
    }()

    private let storeToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "cart.fill"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .systemOrange
        return button
    }()

    private let galleryToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "photo"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .systemBlue
        return button
    }()

    private let currentLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "location.fill"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .systemBlue
        return button
    }()

    private lazy var bottomButtonContainer: UIView = {
        let view = UIView()
        [homeButton, catRegisterButton, logRecordButton].forEach { view.addSubview($0) }
        view.backgroundColor = .white
        view.layer.cornerRadius = 25
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.15
        return view
    }()

    private let homeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "house.fill"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()

    private let catRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.app"), for: .normal)
        button.tintColor = .systemGray
        return button
    }()

    private let logRecordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
        button.tintColor = .systemGray
        return button
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        bind()
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        [mapView, bottomButtonContainer, profileButton, menuToggleButton, storeToggleButton, galleryToggleButton, currentLocationButton].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        super.configureLayout()
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        profileButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(44)
        }

        menuToggleButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(bottomButtonContainer.snp.top).offset(-20)
            make.size.equalTo(44)
        }

        storeToggleButton.snp.makeConstraints { make in
            make.centerY.equalTo(menuToggleButton)
            make.trailing.equalTo(menuToggleButton.snp.leading).offset(-12)
            make.size.equalTo(44)
        }

        galleryToggleButton.snp.makeConstraints { make in
            make.centerY.equalTo(menuToggleButton)
            make.trailing.equalTo(storeToggleButton.snp.leading).offset(-12)
            make.size.equalTo(44)
        }

        currentLocationButton.snp.makeConstraints { make in
            make.bottom.equalTo(menuToggleButton.snp.top).offset(-20)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(44)
        }

        // 하단 컨테이너
        bottomButtonContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(50)
        }

        homeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }

        catRegisterButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }

        logRecordButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-30)
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }
    }

    override func configureView() {
        super.configureView()
    }

    private func setupMapView() {
        mapView.delegate = self

        let initialLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        let regionRadius: CLLocationDistance = 1000

        let coordinateRegion = MKCoordinateRegion(
            center: initialLocation.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )

        mapView.setRegion(coordinateRegion, animated: false)
    }
}

// MARK: Rx Binding
extension HomeViewController {
    private func bind() {
        let input = HomeViewModel.Input(
            viewDidLoad: .just(()),
            menuToggleTapped: menuToggleButton.rx.tap.asObservable(),
            storeToggleTapped: storeToggleButton.rx.tap.asObservable(),
            galleryToggleTapped: galleryToggleButton.rx.tap.asObservable(),
            currentLocationTapped: currentLocationButton.rx.tap.asObservable(),
            homeButtonTapped: homeButton.rx.tap.asObservable(),
            catRegisterTapped: catRegisterButton.rx.tap.asObservable(),
            logRecordTapped: logRecordButton.rx.tap.asObservable(),
            profileTapped: profileButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.isMenuExpanded
            .drive(with: self) { owner, isExpanded in
                owner.toggleMenuButtons(isExpanded)
            }
            .disposed(by: disposeBag)
    }

    private func toggleMenuButtons(_ isExpanded: Bool) {
        isMenuExpanded = isExpanded

        let image = isMenuExpanded ? "chevron.right" : "chevron.left"
        self.menuToggleButton.setImage(UIImage(systemName: image), for: .normal)

        if isExpanded {
            storeToggleButton.isHidden = false
            galleryToggleButton.isHidden = false
        } else {
            self.storeToggleButton.isHidden = true
            self.galleryToggleButton.isHidden = true
        }
    }
}

extension HomeViewController: MKMapViewDelegate {

}
