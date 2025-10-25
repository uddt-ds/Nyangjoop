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
import Toast
import RealmSwift

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

    private let clearRouteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("경로 지우기", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.isHidden = true
        return button
    }()

    private let clusteringThresholdZoom: Double = 0.015
    private var lastClusteringState: Bool = false
    private var isUpdatingAnnotations = false

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        return mapView
    }()

    private let profileButton: UIButton = {
        let button = UIButton()
        button.setImage(.profile, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()
    
    private let churContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.churBg.withAlphaComponent(0.5)
        view.layer.cornerRadius = 22
        return view
    }()
    
    private let churImageBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 18
        return view
    }()
    
    private let churImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .chur
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let churCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let churAddButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let image = UIImage(systemName: "plus", withConfiguration: config)?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .key
        button.layer.cornerRadius = 22
        return button
    }()

    private let menuToggleButton: UIButton = {
        let button = UIButton()
        button.setImage(.cheveronL, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()

    private let storeToggleButton: UIButton = {
        let button = UIButton()
        button.setImage(.fishButton, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()

    private let galleryToggleButton: UIButton = {
        let button = UIButton()
        button.setImage(.gallery, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()

    private let currentLocationButton: UIButton = {
        let button = UIButton()
        button.setImage(.location, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()

    private weak var currentCallOutView: CatCalloutView?
    private var isCalloutTransitioning = false
    private var calloutAnimator: UIViewPropertyAnimator?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupTapGesture()
        bind()
        setupNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        viewWillAppearSubject.onNext(())
        updateChurCountLabel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeCurrentCalloutView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        [mapView, churContainerView, churAddButton, profileButton, menuToggleButton, storeToggleButton, galleryToggleButton, currentLocationButton, clearRouteButton].forEach { view.addSubview($0) }
        
        churContainerView.addSubview(churImageBackgroundView)
        churImageBackgroundView.addSubview(churImageView)
        
        churContainerView.addSubview(churCountLabel)
    }

    override func configureLayout() {
        super.configureLayout()
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        churContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(44)
            make.width.equalTo(120)
        }
        
        churImageBackgroundView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }
        
        churImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }
        
        churCountLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }
        
        churAddButton.snp.makeConstraints { make in
            make.centerX.equalTo(churContainerView.snp.trailing)
            make.centerY.equalTo(churContainerView)
            make.size.equalTo(44)
        }
        
        churContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(44)
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
        
        clearRouteButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
            make.width.equalTo(120)
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
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCatRegistered),
            name: NSNotification.Name("CatRegistered"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHideCallout),
            name: NSNotification.Name("HideCallout"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChurCountUpdated),
            name: NSNotification.Name("ChurCountUpdated"),
            object: nil
        )
    }
    
    private func updateChurCountLabel() {
        let churCount = ChurService.shared.currentChurCount
        churCountLabel.text = "\(churCount)"
    }
    
    private func showChurAddAlert() {
        let churShopVC = ChurShopViewController()
        churShopVC.modalPresentationStyle = .overFullScreen
        churShopVC.modalTransitionStyle = .crossDissolve
        present(churShopVC, animated: true)
    }
    
    @objc private func handleChurCountUpdated() {
        updateChurCountLabel()
    }
    
    @objc private func handleCatRegistered() {
        viewWillAppearSubject.onNext(())
        updateChurCountLabel()
    }
    
    @objc private func handleHideCallout() {
        removeCurrentCalloutView()
    }
    
    @objc private func mapViewTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: mapView)
        
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
        
        output.storeResultMessage
            .filter { !$0.isEmpty }
            .drive(with: self) { owner, message in
                owner.showToast(message: message)
            }
            .disposed(by: disposeBag)
        
        clearRouteButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.clearRoute()
            }
            .disposed(by: disposeBag)
        
        churAddButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.showChurAddAlert()
            }
            .disposed(by: disposeBag)
    }
}

extension HomeViewController {
    private func toggleMenuButtons(_ isExpanded: Bool) {
        isMenuExpanded = isExpanded

        let image: UIImage = isMenuExpanded ? .cheveronR : .cheveronL
        self.menuToggleButton.setImage(image, for: .normal)

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
        let validCats = cats.filter { !$0.isInvalidated }
        
        let existingCatAnnotations = mapView.annotations.compactMap { $0 as? CatAnnotation }.filter { !$0.cat.isInvalidated }
        let existingCatIds = Set(existingCatAnnotations.compactMap { annotation -> ObjectId? in
            guard !annotation.cat.isInvalidated else { return nil }
            return annotation.cat.id
        })
        let newCatIds = Set(validCats.map { $0.id })
        
        let catsToRemove = existingCatAnnotations.filter { annotation in
            guard !annotation.cat.isInvalidated else { return true }
            return !newCatIds.contains(annotation.cat.id)
        }
        let catIdsToAdd = newCatIds.subtracting(existingCatIds)
        let catsToAdd = validCats.filter { catIdsToAdd.contains($0.id) }
        
        let catsToUpdate = validCats.compactMap { newCat -> Cat? in
            guard existingCatIds.contains(newCat.id) else { return nil }
            guard let existingAnnotation = existingCatAnnotations.first(where: { !$0.cat.isInvalidated && $0.cat.id == newCat.id }) else { return nil }
            
            let existingCat = existingAnnotation.cat
            guard !existingCat.isInvalidated else { return newCat }
            
            let hasChanged = existingCat.visitCount != newCat.visitCount ||
                           existingCat.name != newCat.name ||
                           existingCat.lat != newCat.lat ||
                           existingCat.lon != newCat.lon
            
            return hasChanged ? newCat : nil
        }
        
        if !catsToRemove.isEmpty {
            mapView.removeAnnotations(catsToRemove)
            print("마커 삭제: \(catsToRemove.count)개")
        }
        
        if !catsToAdd.isEmpty {
            let newAnnotations = catsToAdd.map { CatAnnotation(cat: $0) }
            mapView.addAnnotations(newAnnotations)
        }
        
        if !catsToUpdate.isEmpty {
            let annotationsToUpdate = existingCatAnnotations.filter { annotation in
                guard !annotation.cat.isInvalidated else { return false }
                return catsToUpdate.contains(where: { $0.id == annotation.cat.id })
            }
            mapView.removeAnnotations(annotationsToUpdate)
            
            let updatedAnnotations = catsToUpdate.map { CatAnnotation(cat: $0) }
            mapView.addAnnotations(updatedAnnotations)
            print("마커 업데이트: \(catsToUpdate.count)개")
        }
        
        currentCats = validCats
        
        if catsToRemove.isEmpty && catsToAdd.isEmpty && catsToUpdate.isEmpty {
        }
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
        if isCalloutTransitioning { return }

        view.subviews.compactMap { $0 as? CatCalloutView }.forEach { $0.removeFromSuperview() }
        currentCalloutView = nil

        guard let catAnnotation = mapView.annotations
            .compactMap({ $0 as? CatAnnotation })
            .first(where: { $0.cat.id == cat.id }) else { return }

        let calloutView = CatCalloutView()
        calloutView.delegate = self
        calloutView.configure(with: cat.name)
        calloutView.alpha = 0
        calloutView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        calloutView.isUserInteractionEnabled = false

        view.addSubview(calloutView)

        let pointTo = mapView.convert(catAnnotation.coordinate, toPointTo: view)
        calloutView.snp.makeConstraints { make in
            make.centerX.equalTo(view.snp.leading).offset(pointTo.x)
            make.bottom.equalTo(view.snp.top).offset(pointTo.y - 60)
            make.width.equalTo(200)
        }
        view.layoutIfNeeded()

        isCalloutTransitioning = true
        let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.7) {
                calloutView.alpha = 1
                calloutView.transform = .identity
            }
            animator.addCompletion { [weak self] _ in
                calloutView.isUserInteractionEnabled = true
                self?.isCalloutTransitioning = false
                self?.calloutAnimator = nil
            }
            calloutAnimator = animator
            animator.startAnimation()

            currentCalloutView = calloutView
    }

    private func removeCurrentCalloutView(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let callout = currentCalloutView else {
            completion?()
            return
        }

        callout.layer.removeAllAnimations()
        calloutAnimator?.stopAnimation(true)
        calloutAnimator = nil

        isCalloutTransitioning = true
        callout.isUserInteractionEnabled = false

        let finish: () -> Void = { [weak self] in
            callout.removeFromSuperview()
            self?.currentCalloutView = nil
            self?.isCalloutTransitioning = false
            completion?()
        }

        if animated {
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn) {
                callout.alpha = 0
                callout.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
            animator.addCompletion { _ in finish() }
            calloutAnimator = animator
            animator.startAnimation()
        } else {
            finish()
        }
    }
    private func pushProfile() {
        let profileVC = ProfileViewController()
        navigationItem.title = ""
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    private func showToast(message: String) {
        view.makeToast(message, duration: 2.0, position: .top)
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
            guard !catAnnotation.cat.isInvalidated else {
                return nil
            }
            
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: CatAnnotationView.identifier
            ) as? CatAnnotationView ?? CatAnnotationView(
                annotation: catAnnotation,
                reuseIdentifier: CatAnnotationView.identifier
            )

            view.configure(with: catAnnotation.cat, showGalleryImage: isShowingGalleryMarkers)
            
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

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        removeCurrentCalloutView()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard !isUpdatingAnnotations else { return }
        
        let currentZoom = mapView.region.span.latitudeDelta
        let shouldEnableClustering = currentZoom > clusteringThresholdZoom
        
        guard shouldEnableClustering != lastClusteringState else { return }
        
        lastClusteringState = shouldEnableClustering
        isUpdatingAnnotations = true
        
        let catAnnotations = mapView.annotations.compactMap { $0 as? CatAnnotation }
        
        if !catAnnotations.isEmpty {
            mapView.removeAnnotations(catAnnotations)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                mapView.addAnnotations(catAnnotations)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isUpdatingAnnotations = false
                }
            }
        } else {
            isUpdatingAnnotations = false
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let clusterAnnotation = view.annotation as? MKClusterAnnotation {
            removeCurrentCalloutView()
            let memberAnnotations = clusterAnnotation.memberAnnotations
            let coordinates = memberAnnotations.compactMap { $0.coordinate }
            
            if coordinates.count > 0 {
                var region = MKCoordinateRegion()
                
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
        
        if let catAnnotation = view.annotation as? CatAnnotation {
            guard !catAnnotation.cat.isInvalidated else {
                mapView.deselectAnnotation(catAnnotation, animated: false)
                return
            }
            
            if let selectedCat = selectedCat, !selectedCat.isInvalidated, selectedCat.id == catAnnotation.cat.id, currentCalloutView != nil {
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
        showCatInfoView(for: cat)
    }
    
    func calloutViewDidTapRelease() {
        guard let cat = selectedCat, !cat.isInvalidated else { return }
        
        let catId = cat.id
        removeCurrentCalloutView()
        
        let alert = UIAlertController(
            title: "놓아주기",
            message: "고양이를 놓아주면 마커에서 삭제되고 \n함께한 기록도 같이 사라져요 \n정말 삭제하시겠어요?",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "아니", style: .cancel)

        let deleteAction = UIAlertAction(title: "응", style: .destructive) { [weak self] _ in
            self?.deleteCat(by: catId)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        present(alert, animated: true)
    }
    
    private func deleteCat(by catId: ObjectId) {
        let annotationsToRemove = mapView.annotations.compactMap { annotation -> CatAnnotation? in
            guard let catAnnotation = annotation as? CatAnnotation else { return nil }
            guard !catAnnotation.cat.isInvalidated else { return catAnnotation }
            return catAnnotation.cat.id == catId ? catAnnotation : nil
        }
        
        if !annotationsToRemove.isEmpty {
            mapView.removeAnnotations(annotationsToRemove)
        }
        
        do {
            try RealmManager.shared.deleteCat(by: catId)
            
            if let selectedCat = selectedCat, !selectedCat.isInvalidated, selectedCat.id == catId {
                self.selectedCat = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.viewWillAppearSubject.onNext(())
            }
        } catch {
            print("고양이 삭제 실패: \(error)")
            showErrorAlert(message: "고양이 삭제에 실패했습니다")
        }
    }
    
    private func showCatInfoView(for cat: Cat) {
        let catInfoView = CatInfoView()
        catInfoView.delegate = self
        catInfoView.alpha = 0
        
        // UIWindow를 통해 최상위에 추가해서 탭바까지 덮기
        guard let window = view.window else {
            view.addSubview(catInfoView)
            catInfoView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            view.layoutIfNeeded()
            catInfoView.configure(with: cat)
            return
        }
        
        window.addSubview(catInfoView)
        
        catInfoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        window.layoutIfNeeded()
        
        catInfoView.configure(with: cat)
    }
}

extension HomeViewController: CatInfoViewDelegate {
    func catInfoViewDidTapConfirm() {
        guard let window = view.window else { return }
        guard let catInfoView = window.subviews.first(where: { $0 is CatInfoView }) else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            catInfoView.alpha = 0
        }) { _ in
            catInfoView.removeFromSuperview()
        }
    }
    
    func catInfoViewDidTapEdit(for cat: Cat) {
        guard let window = view.window else { return }
        guard let catInfoView = window.subviews.first(where: { $0 is CatInfoView }) else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            catInfoView.alpha = 0
        }) { [weak self] _ in
            catInfoView.removeFromSuperview()
            self?.presentEditViewController(for: cat)
        }
    }
    
    private func presentEditViewController(for cat: Cat) {
        print("[HomeVC] presentEditViewController - cat: \(cat.name)")
        let editVC = CatRegisterViewController(isEditMode: true, editingCat: cat)
        editVC.onCatUpdated = { [weak self] in
            self?.viewWillAppearSubject.onNext(())
        }
        
        let navigationController = UINavigationController(rootViewController: editVC)
        navigationController.modalPresentationStyle = .pageSheet
        present(navigationController, animated: true)
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
        
        let locationManagerInstance = CLLocationManager()
        let authStatus = locationManagerInstance.authorizationStatus
        
        print("현재 위치 권한 상태: \(authStatus.rawValue)")
        
        switch authStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("권한 있음 - 경로 찾기 시작")
            locationManager.getCurrentLocation()
                .observe(on: MainScheduler.instance)
                .subscribe { [weak self] currentLocation in
                    guard let self else { return }
                    print("현재 위치로 경로 계산: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
                    self.calculateAndShowRoute(from: currentLocation.coordinate, to: destinationCoordinate, destinationName: cat.name)
                } onFailure: { [weak self] error in
                    guard let self else { return }
                    print("현재 위치 가져오기 실패: \(error.localizedDescription), 기본 위치 사용")
                    self.calculateAndShowRoute(from: AppLocationConfig.defaultCoordinate, to: destinationCoordinate, destinationName: cat.name)
                }
                .disposed(by: disposeBag)
            
        case .denied, .restricted:
            print("권한 거부됨 - 설정 안내")
            showLocationPermissionDeniedAlert()
            
        case .notDetermined:
            print("권한 미결정 - 권한 요청")
            locationManager.getCurrentLocation(requestPermissionIfNeeded: true)
                .observe(on: MainScheduler.instance)
                .subscribe { [weak self] currentLocation in
                    guard let self else { return }
                    print("권한 허용 후 경로 계산")
                    self.calculateAndShowRoute(from: currentLocation.coordinate, to: destinationCoordinate, destinationName: cat.name)
                } onFailure: { [weak self] error in
                    guard let self else { return }
                    print("권한 요청 실패: \(error.localizedDescription)")
                    if let locationError = error as? LocationError, locationError == .permissionDenied {
                        self.showLocationPermissionDeniedAlert()
                    } else {
                        self.calculateAndShowRoute(from: AppLocationConfig.defaultCoordinate, to: destinationCoordinate, destinationName: cat.name)
                    }
                }
                .disposed(by: disposeBag)
            
        @unknown default:
            print("알 수 없는 권한 상태 - 기본 위치 사용")
            calculateAndShowRoute(from: AppLocationConfig.defaultCoordinate, to: destinationCoordinate, destinationName: cat.name)
        }
    }
    
    private func showLocationPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "경로 안내를 사용하려면 설정에서 위치 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        
        let settingsAction = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            self.locationManager.openLocationSettings()
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
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

        showClearRouteButton()
        showRouteInfoToast(route: route, destinationName: destinationName)
    }


    private func showRouteInfoToast(route: MKRoute, destinationName: String) {
        let distance = Measurement(value: route.distance, unit: UnitLength.meters)
        let time = route.expectedTravelTime

        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1

        let distanceString = formatter.string(from: distance.converted(to: .kilometers))
        let timeString = formatTravelTime(time)

        let message = "\(destinationName)추정 위치까지 \(distanceString) | \(timeString)"
        
        let alert = UIAlertController(title: "경로 안내", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func showClearRouteButton() {
        clearRouteButton.isHidden = false
        clearRouteButton.alpha = 0
        clearRouteButton.transform = CGAffineTransform(translationX: 0, y: -20)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.clearRouteButton.alpha = 1
            self.clearRouteButton.transform = .identity
        }
    }
    
    private func hideClearRouteButton() {
        UIView.animate(withDuration: 0.2) {
            self.clearRouteButton.alpha = 0
            self.clearRouteButton.transform = CGAffineTransform(translationX: 0, y: -20)
        } completion: { _ in
            self.clearRouteButton.isHidden = true
        }
    }

    private func clearRoute() {
        mapView.removeOverlays(mapView.overlays)
        hideClearRouteButton()
        
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
