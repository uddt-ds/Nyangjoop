//
//  LocationPickerViewController.swift
//  Nyangjoop
//
//  Created by Lee on 9/28/25.
//

import UIKit
import CoreLocation
import SnapKit
import MapKit
import RxSwift
import RxCocoa

final class LocationPickerViewController: UIViewController {

    weak var delegate: LocationPickerDelegate?

    private let disposeBag = DisposeBag()

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        return mapView
    }()

    private let centerPinImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "mappin.circle.fill")
        view.tintColor = .systemRed
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "지도를 움직여서 위치를 설정하세요"
        label.font = FontSystem.body.font
        label.textAlignment = .center
        return label
    }()

    private let currentLocationButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "location.fill"), for: .normal)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        return button
    }()

    private lazy var selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("이 위치로 설정", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = FontSystem.body.font
        button.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        return button
    }()

    private let locationManager = LocationManager.shared
    private let geocoder = CLGeocoder()
    private var currentCoordinate: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
        setupNavigationBar()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        [mapView, centerPinImageView, addressLabel, currentLocationButton, selectButton].forEach {
            view.addSubview($0)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        centerPinImageView.snp.makeConstraints { make in
            make.centerX.equalTo(mapView)
            make.centerY.equalTo(mapView).offset(-15)
            make.size.equalTo(30)
        }

        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(40)
            make.height.greaterThanOrEqualTo(50)
        }

        currentLocationButton.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.top).offset(-20)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(44)
        }

        selectButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(50)
        }

        currentLocationButton.addTarget(self, action: #selector(currentLocationButtonTapped), for: .touchUpInside)

    }

    private func setupNavigationBar() {
        title = "위치 선택"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
    }

    private func setupMapView() {
        mapView.delegate = self
        mapView.setToDefaultLoction()

        currentCoordinate = AppLocationConfig.defaultCoordinate
        updateAddressLabel(for: AppLocationConfig.defaultCoordinate)
    }

    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "현재 위치를 가져오려면 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func updateAddressLabel(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    print("Geocoding error: \(error)")
                    self.addressLabel.text = "주소를 가져올 수 없습니다"
                    return
                }

                guard let placemark = placemarks?.first else {
                    self.addressLabel.text = "주소를 찾을 수 없습니다"
                    return
                }

                var addressComponents: [String] = []

                if let country = placemark.country { addressComponents.append(country) }
                if let administrativeArea = placemark.administrativeArea { addressComponents.append(administrativeArea) }
                if let locality = placemark.locality { addressComponents.append(locality) }
                if let thoroughfare = placemark.thoroughfare { addressComponents.append(thoroughfare) }
                if let subThoroughfare = placemark.subThoroughfare { addressComponents.append(subThoroughfare) }

                let address = addressComponents.isEmpty ? "주소 정보 없음" : addressComponents.joined(separator: " ")
                self.addressLabel.text = address
            }
        }
    }

    @objc private func selectButtonTapped() {
        guard let coordinate = currentCoordinate,
              let address = addressLabel.text else { return }

        delegate?.didSelectLocation(coordinate: coordinate, address: address)

        dismiss(animated: true)
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func currentLocationButtonTapped() {

        locationManager.getCurrentLocation(requestPermissionIfNeeded: true)
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] location in
                guard let self else { return }

                let region = MKCoordinateRegion(center: location.coordinate,
                                                latitudinalMeters: 1000, longitudinalMeters: 1000)

                self.mapView.setRegion(region, animated: true)
                self.currentCoordinate = location.coordinate
                self.updateAddressLabel(for: location.coordinate)
            } onFailure: { [weak self] error in
                guard let self else { return }

                if let locationError = error as? LocationError {
                    switch locationError {
                    case .permissionDenied:
                        self.showLocationPermissionAlert()
                    default:
                        self.showLocationErrorAlert(message: locationError.errorDescription ?? "위치를 가져올 수 없습니다")
                    }
                } else {
                    self.showLocationErrorAlert(message: "위치를 가져올 수 없습니다")
                }
            }
            .disposed(by: disposeBag)
    }

    private func showLocationErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "위치 오류",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

}

// MARK: - MKMapViewDelegate
extension LocationPickerViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let centerCoordinate = mapView.region.center
        currentCoordinate = centerCoordinate
        updateAddressLabel(for: centerCoordinate)
    }
}
