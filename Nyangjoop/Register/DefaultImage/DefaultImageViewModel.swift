//
//  DefaultImageViewModel.swift
//  Nyangjoop
//
//  Created by Lee on 9/28/25.
//

import UIKit
import RxSwift
import RxCocoa

final class DefaultImageViewModel: ViewModelProtocol {
    private var disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
        let imageSelected: Observable<Int>
        let selectedButtonTapped: Observable<Void>
    }

    struct Output {
        let imageNames: Driver<[String]>
        let selectedIndex: Driver<Int?>
        let isSelectButtonEnabled: Driver<Bool>
        let selectedImage: Driver<UIImage>
    }

    private let imageNames = DefaultCatImages.imageNames

    private let selectedIndexRelay = BehaviorRelay<Int?>(value: nil)

    var numberOfImages: Int {
        return imageNames.count
    }

    func imageName(at index: Int) -> String {
        return imageNames[index]
    }

    func isSelected(at index: Int) -> Bool {
        return selectedIndexRelay.value == index
    }

    func transform(_ input: Input) -> Output {
        let imageNamesDriver = input.viewDidLoad
            .map { [weak self] _ in
                return self?.imageNames ?? []
            }
            .asDriver(onErrorJustReturn: [])

        input.imageSelected
            .do(onNext: { index in
                print("선택된 인덱스 \(index)")
            })
            .bind(to: selectedIndexRelay)
            .disposed(by: disposeBag)

        let selectedIndex = selectedIndexRelay
            .asDriver(onErrorJustReturn: nil)

        let isSelectButtonEnabled = selectedIndexRelay
            .map { $0 != nil }
            .asDriver(onErrorJustReturn: false)

        let selectedImage = input.selectedButtonTapped
            .withLatestFrom(selectedIndexRelay.asObservable())
            .compactMap { [weak self] selectedIndex -> UIImage? in
                guard let self, let index = selectedIndex,
                      index < self.imageNames.count else { return nil }


                let imageName = self.imageNames[index]
                return UIImage(named: imageName) ?? UIImage(named: "cat.fill")!
            }
            .asDriver(onErrorJustReturn: UIImage())

        return Output(imageNames: imageNamesDriver,
                      selectedIndex: selectedIndex,
                      isSelectButtonEnabled: isSelectButtonEnabled,
                      selectedImage: selectedImage)
    }

    func getCurrentSelectedImageName() -> String? {
        guard let selectedIndex = selectedIndexRelay.value,
              selectedIndex < imageNames.count else { return nil }
        return imageNames[selectedIndex]
    }
}

