//
//  DefaultImageViewModel.swift
//  Nyangjoop
//
//  Created by Lee on 9/28/25.
//

import UIKit
import RxSwift
import RxCocoa

// 이미지와 선택 상태를 포함한 모델
struct DefaultImageItem {
    let imageName: String
    let isSelected: Bool
}

final class DefaultImageViewModel: ViewModelProtocol {
    private var disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
        let imageSelected: Observable<Int>
        let selectedButtonTapped: Observable<Void>
    }

    struct Output {
        let imageItems: Driver<[DefaultImageItem]>
        let isSelectButtonEnabled: Driver<Bool>
        let selectedImage: Driver<(image: UIImage, imageName: String)>
    }

    private let imageNames = DefaultCatImages.imageNames
    private let selectedIndexRelay = BehaviorRelay<Int?>(value: nil)

    func transform(_ input: Input) -> Output {
        // 이미지 선택 처리
        input.imageSelected
            .do(onNext: { index in
                print("선택된 인덱스: \(index)")
            })
            .bind(to: selectedIndexRelay)
            .disposed(by: disposeBag)

        // 이미지 아이템 목록 (이미지명 + 선택 상태)
        let imageItems = selectedIndexRelay
            .map { [weak self] selectedIndex -> [DefaultImageItem] in
                guard let self = self else { return [] }
                
                return self.imageNames.enumerated().map { index, imageName in
                    DefaultImageItem(
                        imageName: imageName,
                        isSelected: selectedIndex == index
                    )
                }
            }
            .asDriver(onErrorJustReturn: [])

        // 선택 버튼 활성화 여부
        let isSelectButtonEnabled = selectedIndexRelay
            .map { $0 != nil }
            .asDriver(onErrorJustReturn: false)

        // 선택 완료 시 이미지와 이름 전달 (레이블 명시)
        let selectedImage = input.selectedButtonTapped
            .withLatestFrom(selectedIndexRelay.asObservable())
            .compactMap { [weak self] selectedIndex -> (image: UIImage, imageName: String)? in
                guard let self = self,
                      let index = selectedIndex,
                      index < self.imageNames.count else { return nil }

                let imageName = self.imageNames[index]
                let image = UIImage(named: imageName) ?? UIImage(systemName: "cat.fill")!
                
                return (image: image, imageName: imageName)
            }
            .asDriver(onErrorJustReturn: (image: UIImage(), imageName: ""))

        return Output(
            imageItems: imageItems,
            isSelectButtonEnabled: isSelectButtonEnabled,
            selectedImage: selectedImage
        )
    }
}
