//
//  CatRegisterViewModel.swift
//  Nyangjoop
//
//  Created by Lee on 9/27/25.
//

import UIKit
import CoreLocation
import ImageIO
import RxSwift
import RxCocoa

final class CatRegisterViewModel: ViewModelProtocol {
    private var disposeBag = DisposeBag()
    private let realmManager = RealmManager.shared
    private let locationManager = LocationManager.shared

    struct Input {
        let viewDidLoad: Observable<Void>
        let photoButtonTapped: Observable<Void>
        let photoSelected: Observable<UIImage>
        let defaultImageButtonTapped: Observable<Void>
        let defaultImageSelected: Observable<String>
        let nameTextChanged: Observable<String>
        let genderSelected: Observable<Int>
        let characterSelected: Observable<Int>
        let locationButtonTapped: Observable<Void>
        let locationSet: Observable<CLLocationCoordinate2D>
        let dateSelected: Observable<Date>
        let registerButtonTapped: Observable<Void>
    }

    struct Output {
        let showPhotoSelection: Driver<Void>
        let selectedPhoto: Driver<UIImage>
        let locationText: Driver<String>
        let showLocationPicker: Driver<Void>
        let showDefaultImagePicker: Driver<Void>
        let isRegisterEnabled: Driver<Bool>
        let registrationCompleted: Driver<Void>
        let errorMessage: Driver<String>
    }

    private var selectedImage: UIImage?
    private var extractedLocation: CLLocationCoordinate2D?
    private var extractedDate: Date?
    private var manualLocation: CLLocationCoordinate2D?
    private var imagePath: String?
    private var isDefaultImage = false
    private var defaultImageName: String?

    func transform(_ input: Input) -> Output {
        let showPhotoSelection = input.photoButtonTapped
            .asDriver(onErrorJustReturn: ())

        let showDefaultImagePicker = input.defaultImageButtonTapped
            .asDriver(onErrorJustReturn: ())

        input.defaultImageSelected
            .do { [weak self] imageName in
                guard let self else { return }
                self.isDefaultImage = true
                self.defaultImageName = imageName

                self.selectedImage = UIImage(named: imageName)
            }
            .subscribe()
            .disposed(by: disposeBag)

        let selectedPhoto = input.photoSelected
            .do(onNext: { [weak self] image in
                guard let self else { return }
                self.selectedImage = image
                self.processPhotoMetadata(image)
            })
            .asDriver(onErrorJustReturn: UIImage())

        let locationTextRelay = BehaviorRelay<String>(value: "위치 정보 가져오는 중")

        input.photoSelected
            .flatMap { [weak self] image -> Observable<String> in
                guard let self else { return Observable.just("위치정보 없음") }

                if let coordinate = self.extractLocationFromPhoto(image) {
                    self.extractedLocation = coordinate
                    return self.getAddressFromCoordinate(coordinate)
                } else {
                    return Observable.just("사진에 위치 정보가 없습니다. 수동으로 설정해주세요")
                }
            }
            .bind(to: locationTextRelay)
            .disposed(by: disposeBag)

        input.locationSet
            .do { [weak self] coordinate in
                guard let self else { return }
                self.manualLocation = coordinate
            }
            .flatMap { [weak self] coordinate -> Observable<String> in
                guard let self else { return Observable.just("위치 설정됨") }
                return self.getAddressFromCoordinate(coordinate)
            }
            .bind(to: locationTextRelay)
            .disposed(by: disposeBag)

        let locationText = locationTextRelay.asDriver()

        let showLocationPicker = input.locationButtonTapped
            .asDriver(onErrorJustReturn: ())

        let isRegisterEnabled = Observable.combineLatest(
            input.nameTextChanged,
            input.photoSelected.map { _ in true }.startWith(false),
            locationTextRelay.map { !$0.contains("위치 정보를 가져오는 중") }
        )
            .map { name, hasPhoto, hasLocation in
                return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasPhoto && hasLocation
            }
            .asDriver(onErrorJustReturn: false)

        let registrationResult = input.registerButtonTapped
            .withLatestFrom(Observable.combineLatest(
                input.nameTextChanged,
                input.genderSelected,
                input.characterSelected,
                input.dateSelected
            ))
            .flatMap { [weak self] (name, genderIndex, characterIndex, date) -> Observable<Result<Void, Error>> in
                guard let self else {
                    return Observable.just(.failure(CatRegisterError.unknown))
                }
                return self.registerCat(name: name,
                                        genderIndex: genderIndex,
                                        characterIndex: characterIndex,
                                        date: date)
            }
            .share()

        let registrationCompleted = registrationResult
            .compactMap { result in
                if case .success = result {
                    return ()
                }
                return nil
            }
            .asDriver(onErrorJustReturn: ())

        let errorMessage = registrationResult
            .compactMap { result in
                if case .failure(let error) = result {
                    return error.localizedDescription
                }
                return nil
            }
            .asDriver(onErrorJustReturn: "알 수 없는 오류가 발생했습니다")

        return Output(showPhotoSelection: showPhotoSelection,
                      selectedPhoto: selectedPhoto,
                      locationText: locationText,
                      showLocationPicker: showLocationPicker,
                      showDefaultImagePicker: showDefaultImagePicker,
                      isRegisterEnabled: isRegisterEnabled,
                      registrationCompleted: registrationCompleted,
                      errorMessage: errorMessage)
    }

    private func registerCat(name: String, genderIndex: Int, characterIndex: Int, date: Date) -> Observable<Result<Void, Error>> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onNext(.failure(CatRegisterError.unknown))
                observer.onCompleted()
                return Disposables.create()
            }

            guard let selectedImage = self.selectedImage else {
                observer.onNext(.failure(CatRegisterError.missingPhoto))
                observer.onCompleted()
                return Disposables.create()
            }

            let finalLocation: CLLocationCoordinate2D
            if let manualLocation = self.manualLocation {
                finalLocation = manualLocation
            } else if let extractedLocation = self.extractedLocation {
                finalLocation = extractedLocation
            } else {
                observer.onNext(.failure(CatRegisterError.missingLocation))
                observer.onCompleted()
                return Disposables.create()
            }

            let finalDate = self.extractedDate ?? date

            do {
                if self.isDefaultImage {
                    let randomImageName = DefaultCatImages.imageNames.randomElement() ?? "black1_x1"
                    let cat = Cat(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                  meetDate: finalDate,
                                  gender: genderIndex,
                                  character: characterIndex == 5 ? nil : characterIndex,
                                  drawImage: randomImageName,
                                  lat: finalLocation.latitude,
                                  lon: finalLocation.longitude)

                    try self.realmManager.saveCat(cat)
                } else {
                    guard let imagePath = self.imagePath else {
                        observer.onNext(.failure(CatRegisterError.missingPhoto))
                        observer.onCompleted()
                        return Disposables.create()
                    }

                    let randomImageName = DefaultCatImages.imageNames.randomElement() ?? "black1_x1"

                    let cat = Cat(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                  meetDate: finalDate,
                                  gender: genderIndex,
                                  character: characterIndex == 5 ? nil : characterIndex,
                                  drawImage: randomImageName,
                                  lat: finalLocation.latitude,
                                  lon: finalLocation.longitude)

                    try self.realmManager.saveCat(cat)

                    let visitLog = VisitLog(catId: cat.id,
                                            date: finalDate,
                                            filePath: imagePath,
                                            lat: finalLocation.latitude,
                                            lon: finalLocation.longitude)
                    try self.realmManager.saveVisitLog(visitLog, to: cat)
                }

                observer.onNext(.success(()))
            } catch {
                observer.onNext(.failure(CatRegisterError.saveError(error)))

            }

            observer.onCompleted()
            return Disposables.create()
        }
    }
}

extension CatRegisterViewModel {
    private func processPhotoMetadata(_ image: UIImage) {
        if let date = extractDateFromPhoto(image) {
            extractedDate = date
        }

        imagePath = saveImageToDocuments(image)
    }

    private func extractLocationFromPhoto(_ image: UIImage) -> CLLocationCoordinate2D? {
        guard let imageData = image.jpegData(compressionQuality: 1.0),
              let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String : Any],
              let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String : Any] else {
            return nil
        }

        guard let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double,
              let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String else {
            return nil
        }

        let finalLatitude = latitudeRef == "S" ? -latitude : latitude
        let finalLongitude = longitudeRef == "W" ? -longitude : longitude

        return CLLocationCoordinate2D(latitude: finalLatitude, longitude: finalLongitude)
    }

    private func extractDateFromPhoto(_ image: UIImage) -> Date? {
        guard let imageData = image.jpegData(compressionQuality: 1.0),
              let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String : Any],
              let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String : Any],
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateString)
    }

    private func saveImageToDocuments(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = "cat_\(UUID().uuidString).jpg"
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentPath.appending(path: fileName)

        do {
            try imageData.write(to: filePath)
            return fileName
        } catch {
            print("이미지 저장 실패: \(error)")


            return nil
        }
    }

    private func getAddressFromCoordinate(_ coordinate: CLLocationCoordinate2D) -> Observable<String> {
        return Observable.create { observer in
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error {
                    observer.onNext("주소를 가져올 수 없어요")
                    observer.onCompleted()
                    return
                }

                if let placemark = placemarks?.first {
                    let address = [placemark.administrativeArea,
                                   placemark.locality,
                                   placemark.thoroughfare,
                                   placemark.subThoroughfare]
                        .compactMap { $0 }
                        .joined(separator: " ")

                    observer.onNext(address.isEmpty ? "주소 정보 없음" : address)
                } else {
                    observer.onNext("주소를 가져올 수 없습니다")
                }
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}

enum CatRegisterError: Error, LocalizedError {
    case missingPhoto
    case missingLocation
    case saveError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .missingPhoto:
            return "사진을 선택해주세요"
        case .missingLocation:
            return "위치 정보를 설정해주세요"
        case .saveError(let error):
            return "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}
