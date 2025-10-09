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
    
    var isEditMode: Bool = false
    var editingCat: Cat?
    
    private let locationTextRelay = BehaviorRelay<String>(value: "위치 정보 가져오는 중")

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
        let registrationCompleted: Driver<String>
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
    
    func loadInitialLocation() {
        print("[ViewModel] loadInitialLocation 호출 - isEditMode: \(isEditMode), editingCat: \(String(describing: editingCat?.name))")
        
        guard isEditMode, let cat = editingCat else {
            print("[ViewModel] loadInitialLocation - guard 실패")
            return
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: cat.lat, longitude: cat.lon)
        manualLocation = coordinate
        print("[ViewModel] loadInitialLocation - 기존 좌표 설정: \(coordinate.latitude), \(coordinate.longitude)")
        
        // 좌표로부터 주소 가져오기
        getAddressFromCoordinate(coordinate)
            .take(1)
            .subscribe(onNext: { [weak self] address in
                self?.locationTextRelay.accept(address)
            })
            .disposed(by: disposeBag)
    }

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

        // 등록 버튼 활성화 조건
        // 수정 모드: 이름과 위치만 필수
        // 등록 모드: 사진, 기본 이미지, 이름, 위치 모두 필수
        let isRegisterEnabled = Observable.combineLatest(
            input.photoWithMetadataSelected.map { _ in true }.startWith(false),
            input.defaultImageSelected.map { _ in true }.startWith(false),
            input.nameTextChanged,
            locationTextRelay.asObservable()
        )
            .map { [weak self] hasPhoto, hasDefaultImage, name, locationText in
                guard let self = self else { return false }
                
                let hasValidName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let hasValidLocation = !locationText.contains("위치 정보를 가져오는 중") 
                    && !locationText.contains("위치정보 없음")
                
                // 수정 모드일 때는 사진과 기본 이미지가 없어도 OK (기존 것 사용)
                if self.isEditMode {
                    return hasValidName && hasValidLocation
                } else {
                    return hasPhoto && hasDefaultImage && hasValidName && hasValidLocation
                }
            }
            .asDriver(onErrorJustReturn: false)

        let registrationResult = input.registerButtonTapped
            .withLatestFrom(Observable.combineLatest(
                input.nameTextChanged,
                input.genderSelected,
                input.characterSelected,
                input.dateSelected
            ))
            .flatMap { [weak self] (name, genderIndex, characterIndex, date) -> Observable<Result<String, Error>> in
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
                if case .success(let message) = result {
                    return message
                }
                return nil
            }
            .asDriver(onErrorJustReturn: "고양이가 성공적으로 등록되었습니다!")

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

    private func saveImage() -> String? {
        guard let image = selectedImage else { return nil }
        
        let fileName = "cat_\(UUID().uuidString).jpg"
        let filePath = FileManager.documentsDirectory.appendingPathComponent(fileName)
        
        guard let compressedData = image.jpegData(compressionQuality: 0.5) else {
            print("이미지 압축 실패")
            return nil
        }
        
        do {
            try compressedData.write(to: filePath)
            print("이미지 저장 성공 (50% 퀄리티): \(fileName)")
            return fileName
        } catch {
            print("이미지 저장 실패: \(error)")
            return nil
        }
    }

    private func registerCat(name: String, genderIndex: Int, characterIndex: Int, date: Date) -> Observable<Result<String, Error>> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onNext(.failure(CatRegisterError.unknown))
                observer.onCompleted()
                return Disposables.create()
            }

            // 등록 모드일 때만 사진 필수 체크
            if !self.isEditMode {
                guard self.selectedImage != nil else {
                    observer.onNext(.failure(CatRegisterError.missingPhoto))
                    observer.onCompleted()
                    return Disposables.create()
                }
            }
            
            // 기본 이미지 체크
            let defaultImageName: String
            if let selectedDefaultImage = self.defaultImageName {
                defaultImageName = selectedDefaultImage
            } else if self.isEditMode, let existingCat = self.editingCat {
                // 수정 모드에서 기본 이미지를 선택하지 않았으면 기존 것 사용
                defaultImageName = existingCat.drawImage
            } else {
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
                if self.isEditMode, let existingCat = self.editingCat {
                    // 수정 모드: 기존 고양이 정보 업데이트
                    try self.updateCat(existingCat,
                                     name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                     genderIndex: genderIndex,
                                     characterIndex: characterIndex,
                                     date: finalDate,
                                     defaultImageName: defaultImageName,
                                     location: finalLocation)
                    observer.onNext(.success("고양이 정보가 성공적으로 수정되었습니다!"))
                } else {
                    // 등록 모드: 새로운 고양이 생성
                    // 등록 시점에 이미지 저장
                    guard let savedImagePath = self.saveImage() else {
                        observer.onNext(.failure(CatRegisterError.imageSaveFailed))
                        observer.onCompleted()
                        return Disposables.create()
                    }
                    
                    let cat = Cat(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                  meetDate: finalDate,
                                  gender: genderIndex,
                                  character: characterIndex == 5 ? nil : characterIndex,
                                  drawImage: defaultImageName,
                                  lat: finalLocation.latitude,
                                  lon: finalLocation.longitude)

                    try self.realmManager.saveCat(cat)

                    let visitLog = VisitLog(catId: cat.id,
                                            date: finalDate,
                                            filePath: savedImagePath,
                                            lat: finalLocation.latitude,
                                            lon: finalLocation.longitude)
                    try self.realmManager.saveVisitLog(visitLog, toCatId: cat.id)
                    
                    observer.onNext(.success("고양이가 성공적으로 등록되었습니다!"))
                }
            } catch {
                observer.onNext(.failure(CatRegisterError.saveError(error)))
            }

            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    private func updateCat(_ cat: Cat,
                          name: String,
                          genderIndex: Int,
                          characterIndex: Int,
                          date: Date,
                          defaultImageName: String,
                          location: CLLocationCoordinate2D) throws {
        let realm = try realmManager.getRealm()
        
        try realm.write {
            cat.name = name
            cat.gender = genderIndex
            cat.character = characterIndex == 5 ? nil : characterIndex
            cat.drawImage = defaultImageName
            cat.lat = location.latitude
            cat.lon = location.longitude
            cat.meetDate = date
            
            // 새로운 사진을 선택했을 때만 첫 번째 visitLog의 사진 교체
            if self.selectedImage != nil, let firstVisitLog = cat.visitLogs.first {
                // 기존 이미지 파일 삭제
                let oldFilePath = FileManager.documentsDirectory.appendingPathComponent(firstVisitLog.filePath)
                try? FileManager.default.removeItem(at: oldFilePath)
                
                // 새로운 이미지 저장
                if let savedImagePath = self.saveImage() {
                    firstVisitLog.filePath = savedImagePath
                    firstVisitLog.date = date
                    firstVisitLog.lat = location.latitude
                    firstVisitLog.lon = location.longitude
                }
            }
        }
    }

    private func getAddressFromCoordinate(_ coordinate: CLLocationCoordinate2D) -> Observable<String> {
        return Observable.create { observer in
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error {
                    print("[주소 변환 실패] \(error.localizedDescription)")
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
                    
                    let finalAddress = address.isEmpty ? "주소 정보 없음" : address
                    observer.onNext(finalAddress)
                } else {
                    print("[주소 변환 실패] placemark 없음")
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
    case imageSaveFailed
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
        case .imageSaveFailed:
            return "이미지 저장에 실패했습니다"
        case .saveError(let error):
            return "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}
