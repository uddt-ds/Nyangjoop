//
//  LogRecordViewModel.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import UIKit
import CoreLocation
import RxSwift
import RxCocoa

final class LogRecordViewModel: ViewModelProtocol {
    private var disposeBag = DisposeBag()
    private let realmManager = RealmManager.shared
    private let locationManager = LocationManager.shared

    struct Input {
        let viewDidLoad: Observable<Void>
        let selectedCat: Observable<Cat?>
        let photoButtonTapped: Observable<Void>
        let photoSelected: Observable<UIImage>
        let locationFromPhoto: Observable<CLLocationCoordinate2D>
        let memoTextChanged: Observable<String>
        let saveButtonTapped: Observable<Void>
    }

    struct Output {
        let showPhotoSelection: Driver<Void>
        let selectedPhoto: Driver<UIImage>
        let isSaveEnabled: Driver<Bool>
        let saveCompleted: Driver<Void>
        let errorMessage: Driver<String>
    }

    private var selectedImage: UIImage?
    private var selectedCat: Cat?
    private var imagePath: String?
    private var currentLocation: CLLocationCoordinate2D?

    func transform(_ input: Input) -> Output {
        input.selectedCat
            .subscribe(with: self) { owner, cat in
                owner.selectedCat = cat
            }
            .disposed(by: disposeBag)

        input.locationFromPhoto
            .subscribe(with: self) { owner, coordinate in
                print("사진에서 추출한 위치: \(coordinate.latitude), \(coordinate.longitude)")
                owner.currentLocation = coordinate
            }
            .disposed(by: disposeBag)
        
        // 사진 선택 시 GPS 메타데이터가 없으면 현재 위치 가져오기
        input.photoSelected
            .filter { [weak self] _ in
                // currentLocation이 아직 없거나 기본 위치인 경우
                guard let self else { return false }
                return self.currentLocation == nil || 
                       (self.currentLocation?.latitude == AppLocationConfig.defaultCoordinate.latitude &&
                        self.currentLocation?.longitude == AppLocationConfig.defaultCoordinate.longitude)
            }
            .flatMap { [weak self] _ -> Observable<CLLocation> in
                guard let self else { return Observable.empty() }
                return self.locationManager.getCurrentLocation().asObservable()
                    .catch { _ in
                        let defaultLocation = CLLocation(latitude: AppLocationConfig.defaultCoordinate.latitude,
                                                         longitude: AppLocationConfig.defaultCoordinate.longitude)
                        return Observable.just(defaultLocation)
                    }
            }
            .subscribe(with: self) { owner, location in
                print("사진 촬영 후 현재 위치 가져오기: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                owner.currentLocation = location.coordinate
            }
            .disposed(by: disposeBag)

        input.viewDidLoad
            .flatMap { [weak self] _ -> Observable<CLLocation> in
                guard let self else { return Observable.empty() }
                return self.locationManager.getCurrentLocation().asObservable()
                    .catch { _ in
                        let defaultLocation = CLLocation(latitude: AppLocationConfig.defaultCoordinate.latitude,
                                                         longitude: AppLocationConfig.defaultCoordinate.longitude)
                        return Observable.just(defaultLocation)
                    }
            }
            .subscribe(with: self) { owner, location in
                owner.currentLocation = location.coordinate
            }
            .disposed(by: disposeBag)

        let showPhotoSelection = input.photoButtonTapped
            .asDriver(onErrorJustReturn: ())

        let selectedPhoto = input.photoSelected
            .do(onNext: { [weak self] image in
                guard let self else { return }
                self.selectedImage = image
            })
            .asDriver(onErrorJustReturn: UIImage())

        let isSaveEnabled = input.photoSelected
            .map { _ in true }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        let saveResult = input.saveButtonTapped
            .withLatestFrom(input.memoTextChanged)
            .flatMap { [weak self] memo -> Observable<Result<Void, Error>> in
                guard let self else {
                    return Observable.just(.failure(LogRecordError.unknown))
                }
                return self.saveVisitLog(memo: memo)
            }
            .share()

        let saveCompleted = saveResult
            .compactMap { result in
                if case .success = result {
                    return ()
                }
                return nil
            }
            .asDriver(onErrorJustReturn: ())

        let errorMessage = saveResult
            .compactMap { result in
                if case .failure(let error) = result {
                    return error.localizedDescription
                }
                return nil
            }
            .asDriver(onErrorJustReturn: "알 수 없는 오류가 발생했습니다")

        return Output(showPhotoSelection: showPhotoSelection,
                      selectedPhoto: selectedPhoto,
                      isSaveEnabled: isSaveEnabled,
                      saveCompleted: saveCompleted,
                      errorMessage: errorMessage)
    }

    private func saveVisitLog(memo: String) -> Observable<Result<Void, Error>> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onNext(.failure(LogRecordError.noCatSelected))
                observer.onCompleted()
                return Disposables.create()
            }

            guard let selectedCat = self.selectedCat else {
                observer.onNext(.failure(LogRecordError.noCatSelected))
                observer.onCompleted()
                return Disposables.create()
            }

            guard self.selectedImage != nil else {
                observer.onNext(.failure(LogRecordError.noPhotoSelected))
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 저장 시점에 이미지 저장
            guard let savedImagePath = self.saveImageToDocuments() else {
                observer.onNext(.failure(LogRecordError.imageSaveFailed))
                observer.onCompleted()
                return Disposables.create()
            }

            let location = self.currentLocation ?? AppLocationConfig.defaultCoordinate

            do {
                let visitLog = VisitLog(catId: selectedCat.id,
                                        date: Date(),
                                        filePath: savedImagePath,
                                        memo: memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : memo,
                                        lat: location.latitude,
                                        lon: location.longitude)

                try self.realmManager.saveVisitLog(visitLog, toCatId: selectedCat.id)
                
                NotificationCenter.default.post(name: NSNotification.Name("RefreshVisitLogs"), object: nil)
                
                observer.onNext(.success(()))
            } catch {
                observer.onNext(.failure(LogRecordError.saveError(error)))
            }

            observer.onCompleted()
            return Disposables.create()
        }
    }

    private func saveImageToDocuments() -> String? {
        guard let image = selectedImage else { return nil }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("이미지 압축 실패")
            return nil
        }

        let fileName = "visit_\(UUID().uuidString).jpg"
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentPath.appending(path: fileName)

        do {
            try imageData.write(to: filePath)
            print("이미지 저장 성공 (50% 퀄리티): \(fileName)")
            return fileName
        } catch {
            print("이미지 저장 실패: \(error)")
            return nil
        }
    }
}

enum LogRecordError: Error, LocalizedError {
    case noCatSelected
    case noPhotoSelected
    case imageSaveFailed
    case saveError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .noCatSelected:
            return "고양이를 선택해주세요"
        case .noPhotoSelected:
            return "사진을 선택해주세요"
        case .imageSaveFailed:
            return "이미지 저장에 실패했습니다"
        case .saveError(let error):
            return "저장 중 오류가 발생했어요 \(error.localizedDescription)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}
