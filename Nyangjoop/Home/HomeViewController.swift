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
    private var marketAnnotations: [MarketAnnotation] = []
    private var currentCats: [Cat] = []
    private var isShowingGalleryMarkers = false
    private var isShowingStores = false
    private var currentCalloutView: CatCalloutView?
    private var selectedCat: Cat?

    // 클러스터링 제어
    private let clusteringThresholdZoom: Double = 0.015
    private var lastClusteringState: Bool = false
    private var isUpdatingAnnotations = false

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.showsCompass = false
        return mapView
    }()

    private let profileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .retroYellow
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()

    private let menuToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .retroBlue
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()

    private let storeToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "fish.fill"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .retroYellow
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()

    private let galleryToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "photo"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .retroYellow
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()

    private let currentLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "location.fill"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .retroYellow
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupTapGesture()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        viewWillAppearSubject.onNext(())
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        [mapView, profileButton, menuToggleButton, storeToggleButton, galleryToggleButton, currentLocationButton].forEach { view.addSubview($0) }
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
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.size.equalTo(44)
        }

        menuToggleButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(currentLocationButton.snp.top).offset(-20)
            make.size.equalTo(44)
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
        mapView.register(CatClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: CatClusterAnnotationView.identifier)
        mapView.register(MarketAnnotationView.self, forAnnotationViewWithReuseIdentifier: MarketAnnotationView.identifier)

        let standardConfig = MKStandardMapConfiguration()
        standardConfig.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .airport,
            .bank,
            .gasStation,
            .nationalPark,
            .publicTransport,
            .police,
            .postOffice,
            .school,
            .museum
        ])

        mapView.preferredConfiguration = standardConfig
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapViewTapped))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func mapViewTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        print("Map tapped at: \(location)")
        
        let touchedAnnotations = mapView.annotations(in: mapView.visibleMapRect).filter { annotation in
            guard let catAnnotation = annotation as? CatAnnotation else { return false }
            let annotationPoint = mapView.convert(catAnnotation.coordinate, toPointTo: mapView)
            let distance = hypot(annotationPoint.x - location.x, annotationPoint.y - location.y)
            return distance < 30
        }
        
        print("Touched annotations count: \(touchedAnnotations.count)")
        
        if touchedAnnotations.isEmpty {
            print("Removing callout - empty area tapped")
            removeCurrentCalloutView()
        }
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

        output.storeData
            .drive(with: self) { owner, markets in
                owner.updateMarketMarkers(markets)
            }
            .disposed(by: disposeBag)

        output.isShowingStores
            .drive(with: self) { owner, isShowing in
                owner.isShowingStores = isShowing
                if !isShowing {
                    owner.clearMarketMarkers()
                }
            }
            .disposed(by: disposeBag)

        output.showProfileView
            .drive(with: self) { owner, _ in
                owner.pushProfile()
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

    private func moveToLocation(_ location: CLLocation) {
        let regionRadius: CLLocationDistance = 500
        let coordinateRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )

        mapView.setRegion(coordinateRegion, animated: true)
    }


    private func updateCatMarkers(_ cats: [Cat]) {
        let existingCatAnnotations = mapView.annotations.compactMap { $0 as? CatAnnotation }
        mapView.removeAnnotations(existingCatAnnotations)

        currentCats = cats
        let catAnnotations = cats.map { CatAnnotation(cat: $0) }
        mapView.addAnnotations(catAnnotations)

        print("고양이 마커 업데이트: \(cats.count)마리")
    }

    private func updateCatMarkerImages() {
        let catAnnotations = mapView.annotations.compactMap { $0 as? CatAnnotation }
        mapView.removeAnnotations(catAnnotations)
        mapView.addAnnotations(catAnnotations)
    }

    private func updateMarketMarkers(_ markets: [MarketModel]) {
        mapView.removeAnnotations(marketAnnotations)
        marketAnnotations.removeAll()

        marketAnnotations = markets.map{ MarketAnnotation(market: $0) }
        mapView.addAnnotations(marketAnnotations)
    }

    private func clearMarketMarkers() {
        mapView.removeAnnotations(marketAnnotations)
        marketAnnotations.removeAll()
    }

    private func showCatDetailAlert(_ cat: Cat) {
        selectedCat = cat
        showCalloutView(for: cat)
    }
    
    private func showCalloutView(for cat: Cat) {
        print("showCalloutView called for: \(cat.name)")
        removeCurrentCalloutView()
        
        guard let catAnnotation = mapView.annotations.compactMap({ $0 as? CatAnnotation }).first(where: { $0.cat.id == cat.id }) else {
            print("어노테이션을 찾을 수 없음")
            return
        }
        
        let calloutView = CatCalloutView()
        calloutView.delegate = self
        calloutView.configure(with: cat.name)
        
        view.addSubview(calloutView)
        print("Callout view added to view hierarchy")
        
        let annotationPoint = mapView.convert(catAnnotation.coordinate, toPointTo: view)
        print("Annotation point: \(annotationPoint)")
        
        calloutView.snp.makeConstraints { make in
            make.centerX.equalTo(view.snp.leading).offset(annotationPoint.x)
            make.bottom.equalTo(view.snp.top).offset(annotationPoint.y - 60)
            make.width.equalTo(200)
        }
        
        view.layoutIfNeeded()
        print("Callout frame after layout: \(calloutView.frame)")
        
        calloutView.alpha = 0
        calloutView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            calloutView.alpha = 1
            calloutView.transform = .identity
            print("Animation started")
        } completion: { _ in
            print("Animation completed")
        }
        
        currentCalloutView = calloutView
    }
    
    private func removeCurrentCalloutView() {
        guard let callout = currentCalloutView else { return }
        print("removeCurrentCalloutView called")
        
        UIView.animate(withDuration: 0.2) {
            callout.alpha = 0
            callout.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            callout.removeFromSuperview()
            self.currentCalloutView = nil
            print("Callout removed")
        }
    }

    private func pushProfile() {
        let profileVC = ProfileViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

extension HomeViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        if let clusterAnnotation = annotation as? MKClusterAnnotation {
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: CatClusterAnnotationView.identifier
            ) as? CatClusterAnnotationView
            ?? CatClusterAnnotationView(annotation: clusterAnnotation,
                                        reuseIdentifier: CatClusterAnnotationView.identifier)
            view.configure(with: clusterAnnotation)
            return view
        }

        if let catAnnotation = annotation as? CatAnnotation {
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: CatAnnotationView.identifier
            ) as? CatAnnotationView ?? CatAnnotationView(
                annotation: catAnnotation,
                reuseIdentifier: CatAnnotationView.identifier
            )

            view.configure(with: catAnnotation.cat, showGalleryImage: isShowingGalleryMarkers)
            
            // 지도 줌 레벨에 따라 클러스터링 제어
            let currentZoom = mapView.region.span.latitudeDelta
            let shouldEnableClustering = currentZoom > clusteringThresholdZoom
            
            if shouldEnableClustering {
                view.clusteringIdentifier = "catCluster"
            } else {
                view.clusteringIdentifier = nil
            }

            return view
        }

        if let marketAnnotation = annotation as? MarketAnnotation {
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: MarketAnnotationView.identifier
            ) as? MarketAnnotationView
            ?? MarketAnnotationView(annotation: marketAnnotation,
                                    reuseIdentifier: MarketAnnotationView.identifier)
            return view
        }

        return nil
    }

    // 지도 영역 변경 시 annotation 갱신 - 깜빡임 방지
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        removeCurrentCalloutView()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // 이미 업데이트 중이면 무시
        guard !isUpdatingAnnotations else { return }
        
        let currentZoom = mapView.region.span.latitudeDelta
        let shouldEnableClustering = currentZoom > clusteringThresholdZoom
        
        // 클러스터링 상태가 변경되었을 때만 업데이트
        guard shouldEnableClustering != lastClusteringState else { return }
        
        print("줌레벨: \(String(format: "%.4f", currentZoom)), 클러스터링: \(shouldEnableClustering ? "ON" : "OFF")")
        
        lastClusteringState = shouldEnableClustering
        isUpdatingAnnotations = true
        
        // annotation을 제거하고 다시 추가해야 클러스터링이 적용됨
        let catAnnotations = mapView.annotations.compactMap { $0 as? CatAnnotation }
        
        if !catAnnotations.isEmpty {
            mapView.removeAnnotations(catAnnotations)
            
            // 즉시 다시 추가 (대기 시간 최소화)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                mapView.addAnnotations(catAnnotations)
                
                // 업데이트 완료 후 플래그 해제 (짧은 대기 시간)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isUpdatingAnnotations = false
                }
            }
        } else {
            isUpdatingAnnotations = false
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // 클러스터를 선택하면 확대
        if let clusterAnnotation = view.annotation as? MKClusterAnnotation {
            removeCurrentCalloutView()
            let memberAnnotations = clusterAnnotation.memberAnnotations
            let coordinates = memberAnnotations.compactMap { $0.coordinate }
            
            if coordinates.count > 0 {
                var region = MKCoordinateRegion()
                
                // 모든 annotation을 포함하는 영역 계산
                var minLat = coordinates[0].latitude
                var maxLat = coordinates[0].latitude
                var minLon = coordinates[0].longitude
                var maxLon = coordinates[0].longitude
                
                for coordinate in coordinates {
                    minLat = min(minLat, coordinate.latitude)
                    maxLat = max(maxLat, coordinate.latitude)
                    minLon = min(minLon, coordinate.longitude)
                    maxLon = max(maxLon, coordinate.longitude)
                }
                
                region.center.latitude = (minLat + maxLat) / 2
                region.center.longitude = (minLon + maxLon) / 2
                region.span.latitudeDelta = (maxLat - minLat) * 1.5
                region.span.longitudeDelta = (maxLon - minLon) * 1.5
                
                mapView.setRegion(region, animated: true)
            }
            
            mapView.deselectAnnotation(clusterAnnotation, animated: false)
            return
        }
        
        // 개별 고양이 선택
        if let catAnnotation = view.annotation as? CatAnnotation {
            // 이미 선택된 고양이를 다시 누르면 callout 닫기
            if let selectedCat = selectedCat, selectedCat.id == catAnnotation.cat.id, currentCalloutView != nil {
                removeCurrentCalloutView()
                self.selectedCat = nil
            } else {
                removeCurrentCalloutView()
                catAnnotationTappedSubject.onNext(catAnnotation.cat)
            }
            mapView.deselectAnnotation(catAnnotation, animated: false)
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

extension HomeViewController: CatCalloutViewDelegate {
    func calloutViewDidTapDirections() {
        guard let cat = selectedCat else { return }
        removeCurrentCalloutView()
        showDirections(to: cat)
    }
    
    func calloutViewDidTapInfo() {
        guard let cat = selectedCat else { return }
        removeCurrentCalloutView()
        print("고양이 정보 보기 - \(cat.name)")
    }
}

extension HomeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
        
        locationManager.getCurrentLocation()
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] currentLocation in
                guard let self else { return }
                self.moveToLocation(currentLocation)
            } onFailure: { [weak self] _ in
                guard let self else { return }
                self.mapView.setToDefaultLoction(animated: true)
            }
            .disposed(by: disposeBag)
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
        showErrorAlert(message: message)
    }
}
