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
        let photoWithMetadataSelected: Observable<PhotoWithMetadata>
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
        let selectedPhoto: Driver<UIImage>
        let selectedDefaultImage: Driver<UIImage>
        let locationText: Driver<String>
        let showLocationPicker: Driver<Void>
        let isRegisterEnabled: Driver<Bool>
        let registrationCompleted: Driver<Void>
        let errorMessage: Driver<String>
        let extractedDate: Driver<Date?>
    }

    private var selectedImage: UIImage?
    private var originalImageData: Data?
    private var extractedLocation: CLLocationCoordinate2D?
    private var extractedDate: Date?
    private var manualLocation: CLLocationCoordinate2D?
    private var imagePath: String?
    private var defaultImageName: String?

    func transform(_ input: Input) -> Output {
        let extractedDateRelay = BehaviorRelay<Date?>(value: nil)
        let selectedDefaultImageRelay = PublishRelay<UIImage>()

        // 메타데이터 포함 사진 처리
        let selectedPhoto = input.photoWithMetadataSelected
            .do(onNext: { [weak self] photoWithMetadata in
                guard let self else { return }
                
                self.selectedImage = photoWithMetadata.image
                self.originalImageData = photoWithMetadata.originalData
                
                // 메타데이터에서 추출된 정보 저장
                if let location = photoWithMetadata.location {
                    print("사진에서 위치 추출됨: \(location.latitude), \(location.longitude)")
                    self.extractedLocation = location
                } else {
                    print("사진에 위치 정보 없음")
                }
                
                if let date = photoWithMetadata.date {
                    print("사진에서 날짜 추출됨: \(date)")
                    self.extractedDate = date
                    extractedDateRelay.accept(date)
                } else {
                    print("사진에 날짜 정보 없음")
                }
                
                // 이미지 저장
                self.saveImage()
            })
            .map { $0.image }
            .asDriver(onErrorJustReturn: UIImage())

        // 기본 이미지 선택 처리
        input.defaultImageSelected
            .do(onNext: { [weak self] imageName in
                guard let self else { return }
                self.defaultImageName = imageName
                if let image = UIImage(named: imageName) {
                    selectedDefaultImageRelay.accept(image)
                }
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        let selectedDefaultImage = selectedDefaultImageRelay.asDriver(onErrorJustReturn: UIImage())

        let locationTextRelay = BehaviorRelay<String>(value: "위치 정보 가져오는 중")

        // 사진에서 위치 추출 시 주소 가져오기
        input.photoWithMetadataSelected
            .flatMap { [weak self] photoWithMetadata -> Observable<String> in
                guard let self else { return Observable.just("위치정보 없음") }

                if let coordinate = photoWithMetadata.location {
                    return self.getAddressFromCoordinate(coordinate)
                } else {
                    return Observable.just("사진에 위치 정보가 없습니다. 수동으로 설정해주세요")
                }
            }
            .bind(to: locationTextRelay)
            .disposed(by: disposeBag)

        // 수동 위치 설정
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

        // 등록 버튼 활성화 조건: 사진, 기본 이미지, 이름, 위치 모두 필수
        let isRegisterEnabled = Observable.combineLatest(
            input.photoWithMetadataSelected.map { _ in true }.startWith(false),
            input.defaultImageSelected.map { _ in true }.startWith(false),
            input.nameTextChanged,
            locationTextRelay.asObservable()
        )
            .map { hasPhoto, hasDefaultImage, name, locationText in
                let hasValidName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let hasValidLocation = !locationText.contains("위치 정보를 가져오는 중") 
                    && !locationText.contains("위치정보 없음")
                
                return hasPhoto && hasDefaultImage && hasValidName && hasValidLocation
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

        return Output(selectedPhoto: selectedPhoto,
                      selectedDefaultImage: selectedDefaultImage,
                      locationText: locationText,
                      showLocationPicker: showLocationPicker,
                      isRegisterEnabled: isRegisterEnabled,
                      registrationCompleted: registrationCompleted,
                      errorMessage: errorMessage,
                      extractedDate: extractedDateRelay.asDriver())
    }

    private func saveImage() {
        if let data = originalImageData {
            // 원본 데이터 저장 (메타데이터 포함)
            let fileName = "cat_\(UUID().uuidString).jpg"
            let filePath = FileManager.documentsDirectory.appendingPathComponent(fileName)
            
            do {
                try data.write(to: filePath)
                self.imagePath = fileName
                print("이미지 저장 성공 (메타데이터 포함): \(fileName)")
            } catch {
                print("이미지 저장 실패: \(error)")
            }
        } else if let image = selectedImage {
            // 원본 데이터가 없으면 JPEG 변환
            imagePath = FileManager.saveImage(image)
            print("이미지 저장 (메타데이터 없음): \(imagePath ?? "nil")")
        }
    }

    private func registerCat(name: String, genderIndex: Int, characterIndex: Int, date: Date) -> Observable<Result<Void, Error>> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onNext(.failure(CatRegisterError.unknown))
                observer.onCompleted()
                return Disposables.create()
            }

            // 실제 사진 필수 체크
            guard self.selectedImage != nil else {
                observer.onNext(.failure(CatRegisterError.missingPhoto))
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 이미지 경로 필수 체크
            guard let imagePath = self.imagePath else {
                observer.onNext(.failure(CatRegisterError.missingPhoto))
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 기본 이미지 필수 체크
            guard let defaultImageName = self.defaultImageName else {
                observer.onNext(.failure(CatRegisterError.missingDefaultImage))
                observer.onCompleted()
                return Disposables.create()
            }

            // 위치 정보 필수 체크
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

            // 메타데이터에서 추출된 날짜 우선 사용
            let finalDate = self.extractedDate ?? date

            do {
                let cat = Cat(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                              meetDate: finalDate,
                              gender: genderIndex,
                              character: characterIndex == 5 ? nil : characterIndex,
                              drawImage: defaultImageName,  // 선택한 기본 이미지 사용
                              lat: finalLocation.latitude,
                              lon: finalLocation.longitude)

                try self.realmManager.saveCat(cat)

                // 첫 방문 기록 자동 생성 (실제 사진 사용)
                let visitLog = VisitLog(catId: cat.id,
                                        date: finalDate,
                                        filePath: imagePath,
                                        lat: finalLocation.latitude,
                                        lon: finalLocation.longitude)
                try self.realmManager.saveVisitLog(visitLog, to: cat)

                observer.onNext(.success(()))
            } catch {
                observer.onNext(.failure(CatRegisterError.saveError(error)))
            }

            observer.onCompleted()
            return Disposables.create()
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
    case missingDefaultImage
    case missingLocation
    case saveError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .missingPhoto:
            return "고양이 사진을 선택해주세요"
        case .missingDefaultImage:
            return "지도 표시용 이미지를 선택해주세요"
        case .missingLocation:
            return "위치 정보를 설정해주세요"
        case .saveError(let error):
            return "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}
