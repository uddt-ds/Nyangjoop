//
//  PhotoPickerManager.swift
//  Nyangjoop
//
//  Created by Lee on 9/30/25.
//

import UIKit
import PhotosUI
import RxSwift
import RxCocoa
import CoreLocation
import ImageIO

struct PhotoWithMetadata {
    let image: UIImage
    let location: CLLocationCoordinate2D?
    let date: Date?
    let originalData: Data?  // 원본 데이터 (메타데이터 포함)
}

final class PhotoPickerManager: NSObject {
    
    private weak var presentingViewController: UIViewController?
    private let selectedPhotoSubject = PublishSubject<PhotoWithMetadata>()
    private let isLoadingSubject = PublishSubject<Bool>()
    private let disposeBag = DisposeBag()
    
    var selectedPhoto: Observable<PhotoWithMetadata> {
        return selectedPhotoSubject.asObservable()
    }
    
    var isLoading: Observable<Bool> {
        return isLoadingSubject.asObservable()
    }
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }
    
    /// 사진 선택 액션시트 표시
    func showPhotoSelectionActionSheet() {
        guard let presentingVC = presentingViewController else { return }
        
        let alert = UIAlertController(title: "사진 선택", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
            self?.presentCamera()
        })
        
        alert.addAction(UIAlertAction(title: "사진 앨범", style: .default) { [weak self] _ in
            self?.presentPhotoLibrary()
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        presentingVC.present(alert, animated: true)
    }
    
    /// 카메라 실행
    private func presentCamera() {
        guard let presentingVC = presentingViewController else { return }
        
        let customCamera = CustomCameraViewController()
        customCamera.delegate = self
        customCamera.modalPresentationStyle = .fullScreen
        presentingVC.present(customCamera, animated: false)
    }
    
    /// 사진 앨범 실행 (메타데이터 포함)
    private func presentPhotoLibrary() {
        guard let presentingVC = presentingViewController else { return }
        
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        presentingVC.present(picker, animated: true)
    }
    
    /// 이미지에서 메타데이터 추출
    private func extractMetadata(from imageData: Data) -> (location: CLLocationCoordinate2D?, date: Date?) {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            print("메타데이터 추출 실패")
            return (nil, nil)
        }
        
        print("메타데이터: \(metadata.keys)")
        
        // GPS 정보 추출
        var location: CLLocationCoordinate2D?
        if let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            print("GPS 정보 발견: \(gps)")
            
            if let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
               let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double,
               let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
               let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {
                
                let finalLatitude = latitudeRef == "S" ? -latitude : latitude
                let finalLongitude = longitudeRef == "W" ? -longitude : longitude
                
                location = CLLocationCoordinate2D(latitude: finalLatitude, longitude: finalLongitude)
                print("위치 추출 성공: \(finalLatitude), \(finalLongitude)")
            }
        } else {
            print("GPS 정보 없음")
        }
        
        // 날짜 정보 추출
        var date: Date?
        if let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            
            print("날짜 정보 발견: \(dateString)")
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            date = formatter.date(from: dateString)
            
            if date != nil {
                print("날짜 추출 성공: \(dateString)")
            }
        } else {
            print("날짜 정보 없음")
        }
        
        return (location, date)
    }
}

// MARK: - CustomCameraDelegate
extension PhotoPickerManager: CustomCameraDelegate {
    func didCaptureImage(_ image: UIImage) {
        isLoadingSubject.onNext(true)
        
        LocationManager.shared.getCurrentLocation(requestPermissionIfNeeded: false)
            .subscribe { [weak self] location in
                guard let self = self else { return }
                print("현재 위치 가져오기 성공: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                let photoWithMetadata = PhotoWithMetadata(
                    image: image,
                    location: location.coordinate,
                    date: Date(),
                    originalData: image.jpegData(compressionQuality: 0.8)
                )
                self.selectedPhotoSubject.onNext(photoWithMetadata)
                self.isLoadingSubject.onNext(false)

            } onFailure: { [weak self] error in
                guard let self = self else { return }
                print("현재 위치 가져오기 실패 (권한 없음 또는 오류): \(error)")
                let photoWithMetadata = PhotoWithMetadata(
                    image: image,
                    location: nil,
                    date: Date(),
                    originalData: image.jpegData(compressionQuality: 0.8)
                )
                self.selectedPhotoSubject.onNext(photoWithMetadata)
                self.isLoadingSubject.onNext(false)
            }
            .disposed(by: disposeBag)
    }
    
    func didRequestRetake() {
        // 재촬영 요청 시 처리
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PhotoPickerManager: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else {
            picker.dismiss(animated: true)
            return
        }
        
        isLoadingSubject.onNext(true)
        
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        if let data = data {
                            print("원본 데이터 로드 성공: \(data.count) bytes")
                            
                            guard let image = UIImage(data: data) else {
                                print("이미지 변환 실패")
                                DispatchQueue.main.async {
                                    self.isLoadingSubject.onNext(false)
                                }
                                return
                            }
                            
                            let resizedImage = image.resizeIfNeeded(maxDimension: 2000)
                            let metadata = self.extractMetadata(from: data)
                            
                            DispatchQueue.main.async {
                                let photoWithMetadata = PhotoWithMetadata(
                                    image: resizedImage,
                                    location: metadata.location,
                                    date: metadata.date,
                                    originalData: data
                                )
                                
                                self.selectedPhotoSubject.onNext(photoWithMetadata)
                                self.isLoadingSubject.onNext(false)
                            }
                        } else {
                            print("원본 데이터 로드 실패")
                            
                            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                                if let image = object as? UIImage {
                                    DispatchQueue.main.async {
                                        let resizedImage = image.resizeIfNeeded(maxDimension: 2000)
                                        let photoWithMetadata = PhotoWithMetadata(
                                            image: resizedImage,
                                            location: nil,
                                            date: nil,
                                            originalData: nil
                                        )
                                        
                                        self.selectedPhotoSubject.onNext(photoWithMetadata)
                                        self.isLoadingSubject.onNext(false)
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.isLoadingSubject.onNext(false)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            let resizedImage = image.resizeIfNeeded(maxDimension: 2000)
                            let photoWithMetadata = PhotoWithMetadata(
                                image: resizedImage,
                                location: nil,
                                date: nil,
                                originalData: nil
                            )
                            
                            self.selectedPhotoSubject.onNext(photoWithMetadata)
                            self.isLoadingSubject.onNext(false)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isLoadingSubject.onNext(false)
                        }
                    }
                }
            }
        }
    }
}
