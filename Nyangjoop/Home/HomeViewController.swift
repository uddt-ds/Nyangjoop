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

    private let locationManager = LocationManager.shared

    private let viewWillAppearSubject = PublishSubject<Void>()

    private var isMenuExpanded = false

    private let catAnnotationTappedSubject = PublishSubject<Cat>()
    private var currentCats: [Cat] = []
    private var isShowingGalleryMarkers = false

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.onNext(())
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


}

extension HomeViewController {
    private func setupMapView() {
        mapView.delegate = self
        mapView.setToDefaultLoction()
        mapView.register(CatAnnotationView.self, forAnnotationViewWithReuseIdentifier: CatAnnotationView.identifier)
    }

    private func moveToLocation(_ location: CLLocation) {
        let regionRadius: CLLocationDistance = 500
        let coordinateRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )

        mapView.setRegion(coordinateRegion, animated: true)
    }
}

// MARK: Rx Binding
extension HomeViewController {
    private func bind() {
        let input = HomeViewModel.Input(
            viewDidLoad: .just(()),
            viewWillAppear: viewWillAppearSubject.asObservable(),
            menuToggleTapped: menuToggleButton.rx.tap.asObservable(),
            storeToggleTapped: storeToggleButton.rx.tap.asObservable(),
            galleryToggleTapped: galleryToggleButton.rx.tap.asObservable(),
            currentLocationTapped: currentLocationButton.rx.tap.asObservable(),
            homeButtonTapped: homeButton.rx.tap.asObservable(),
            catRegisterTapped: catRegisterButton.rx.tap.asObservable(),
            logRecordTapped: logRecordButton.rx.tap.asObservable(),
            profileTapped: profileButton.rx.tap.asObservable(),
            catAnnotationTapped: catAnnotationTappedSubject.asObservable()
        )

        let output = viewModel.transform(input)

        output.cats
            .drive(with: self) { owner, cats in
                owner.updateCatMarkers(cats)
            }
            .disposed(by: disposeBag)

        output.isMenuExpanded
            .drive(with: self) { owner, isExpanded in
                owner.toggleMenuButtons(isExpanded)
            }
            .disposed(by: disposeBag)

        output.showGalleryMarkers
            .drive(with: self) { owner, showGallery in
                owner.isShowingGalleryMarkers = showGallery
                owner.updateCatMarkerImages()
            }
            .disposed(by: disposeBag)


        output.moveToCurrentLocation
            .drive(with: self) { owner, location in
                owner.moveToLocation(location)
            }
            .disposed(by: disposeBag)

        output.locationError
            .drive(with: self) { owner, errorMessage in
                owner.showErrorAlert(message: errorMessage)
            }
            .disposed(by: disposeBag)

        output.showLocationPermissionAlert
            .drive(with: self) { owner, _ in
                owner.showLocationPermissionAlert()
            }
            .disposed(by: disposeBag)

        output.showCatDetail
            .drive(with: self) { owner, cat in
                owner.showCatDetailAlert(cat)
            }
            .disposed(by: disposeBag)

        output.navigateToCatRegister
            .drive(with: self) { owner, _ in
                owner.presentCatRegisterViewController()
            }
            .disposed(by: disposeBag)


    }
}

extension HomeViewController {
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

    private func updateCatMarkers(_ cats: [Cat]) {
        let existingCatAnnotations = mapView.annotations.compactMap { $0 as? CatAnnotation }
        mapView.removeAnnotations(existingCatAnnotations)

        currentCats = cats
        let catAnnotations = cats.map { CatAnnotation(cat: $0) }
        mapView.addAnnotations(catAnnotations)
    }

    private func updateCatMarkerImages() {
        for annotation in mapView.annotations {
            if let catAnnotation = annotation as? CatAnnotation,
               let annotationView = mapView.view(for: annotation) as? CatAnnotationView {
                annotationView.configure(with: catAnnotation.cat, showGalleryImage: isShowingGalleryMarkers)
            }
        }
    }

    private func presentCatRegisterViewController() {
        let catRegisterVC = CatRegisterViewController()
        let nav = UINavigationController(rootViewController: catRegisterVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "위치 오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showLocationPermissionAlert() {
         let alert = UIAlertController(
             title: "위치 권한 필요",
             message: "현재 위치 기능을 사용하려면 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
             preferredStyle: .alert
         )

         alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { [weak self] _ in
             guard let self else { return }
             locationManager.openLocationSettings()
         })

         alert.addAction(UIAlertAction(title: "취소", style: .cancel))

         present(alert, animated: true)
     }

    private func showCatDetailAlert(_ cat: Cat) {
         let alert = UIAlertController(
             title: cat.name,
             message: "이 고양이와 관련된 작업을 선택해주세요.",
             preferredStyle: .actionSheet
         )

         alert.addAction(UIAlertAction(title: "길찾기", style: .default) { [weak self] _ in
             guard let self else { return }
             self.showDirections(to: cat)
         })

         alert.addAction(UIAlertAction(title: "고양이 정보 보기", style: .default) { _ in
             print("고양이 정보 보기 - \(cat.name)")
         })

         alert.addAction(UIAlertAction(title: "취소", style: .cancel))

         present(alert, animated: true)
     }

}

extension HomeViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let catAnnotation = view.annotation as? CatAnnotation {
            catAnnotationTappedSubject.onNext(catAnnotation.cat)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .retroRed
            renderer.lineWidth = 4.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

extension HomeViewController {

    private func showDirections(to cat: Cat) {
        let destinationCoordinate = CLLocationCoordinate2D(latitude: cat.lat, longitude: cat.lon)

        locationManager.getCurrentLocation()
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] currentLocation in
                guard let self else { return }
                self.calculateAndShowRoute(from: currentLocation.coordinate, to: destinationCoordinate, destinationName: cat.name)
            } onFailure: { [weak self] _ in
                guard let self else { return }
                self.calculateAndShowRoute(from: AppLocationConfig.defaultCoordinate, to: destinationCoordinate, destinationName: cat.name)
            }
            .disposed(by: disposeBag)

    }

    private func calculateAndShowRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, destinationName: String) {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        destinationMapItem.name = destinationName

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .walking

        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] response, error in
            guard let self else { return }

            if let error {
                self.showRouteError(message: "경로를 찾을 수 없습니다")
                return
            }

            guard let response, let route = response.routes.first else {
                self.showRouteError(message: "경로를 찾을 수 없습니다")
                return
            }

            self.displayRoute(route, destinationName: destinationName)
        }
    }

    private func displayRoute(_ route: MKRoute, destinationName: String) {
        mapView.removeOverlays(mapView.overlays)

        mapView.addOverlay(route.polyline)

        let rect = route.polyline.boundingMapRect
        let region = MKCoordinateRegion(rect)
        let adjustedRegion = mapView.regionThatFits(region)
        mapView.setRegion(adjustedRegion, animated: true)

        showRouteInfo(route: route, destinationName: destinationName)
    }

    private func showRouteInfo(route: MKRoute, destinationName: String) {
        let distance = Measurement(value: route.distance, unit: UnitLength.meters)
        let time = route.expectedTravelTime

        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1

        let distanceString = formatter.string(from: distance.converted(to: .kilometers))
        let timeString = formatTravelTime(time)

        let alert = UIAlertController(title: "\(destinationName)까지의 경로", message: "거리: \(distanceString) | 시간: \(timeString)", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "경로 지우기", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.clearRoute()
        })

        alert.addAction(UIAlertAction(title: "확인", style: .default))

        present(alert, animated: true)
    }

    private func clearRoute() {
        mapView.removeOverlays(mapView.overlays)
        mapView.setToDefaultLoction(animated: true)
    }

    private func formatTravelTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        if minutes < 60 {
            return "\(minutes)분"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)시간 \(remainingMinutes)분"
        }
    }

    private func showRouteError(message: String) {
        let alert = UIAlertController(title: "경로 오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

