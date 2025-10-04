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
    private let disposeBag = DisposeBag()
    
    var selectedPhoto: Observable<PhotoWithMetadata> {
        return selectedPhotoSubject.asObservable()
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
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
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
        
        // 위치 권한이 있으면 현재 위치를 가져오고, 없으면 nil로 처리
        LocationManager.shared.getCurrentLocation(requestPermissionIfNeeded: false)
            .subscribe { location in
                print("현재 위치 가져오기 성공: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                let photoWithMetadata = PhotoWithMetadata(
                    image: image,
                    location: location.coordinate,
                    date: Date(),
                    originalData: image.jpegData(compressionQuality: 0.8)
                )
                self.selectedPhotoSubject.onNext(photoWithMetadata)

            } onFailure: { error in
                print("현재 위치 가져오기 실패 (권한 없음 또는 오류): \(error)")
                // 위치 정보 없이 사진만 전달
                let photoWithMetadata = PhotoWithMetadata(
                    image: image,
                    location: nil,
                    date: Date(),
                    originalData: image.jpegData(compressionQuality: 0.8)
                )
                self.selectedPhotoSubject.onNext(photoWithMetadata)
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
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        // 먼저 이미지 로드
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            guard let self = self,
                  let image = object as? UIImage else { return }
            
            // 원본 데이터 로드 (메타데이터 포함)
            if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                    DispatchQueue.main.async {
                        if let data = data {
                            print("원본 데이터 로드 성공: \(data.count) bytes")
                            let metadata = self.extractMetadata(from: data)
                            
                            let photoWithMetadata = PhotoWithMetadata(
                                image: image,
                                location: metadata.location,
                                date: metadata.date,
                                originalData: data
                            )
                            
                            self.selectedPhotoSubject.onNext(photoWithMetadata)
                        } else {
                            print("원본 데이터 로드 실패")
                            // 메타데이터 없이라도 이미지는 전달
                            let photoWithMetadata = PhotoWithMetadata(
                                image: image,
                                location: nil,
                                date: nil,
                                originalData: nil
                            )
                            
                            self.selectedPhotoSubject.onNext(photoWithMetadata)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    // 메타데이터 없이라도 이미지는 전달
                    let photoWithMetadata = PhotoWithMetadata(
                        image: image,
                        location: nil,
                        date: nil,
                        originalData: nil
                    )
                    
                    self.selectedPhotoSubject.onNext(photoWithMetadata)
                }
            }
        }
    }
}
