//
//  LogViewModel.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa

// 고양이 선택 상태를 포함한 모델
struct CatWithSelection {
    let cat: Cat?  // nil이면 "전체"
    let isSelected: Bool
}

final class LogViewModel: ViewModelProtocol {
    private var disposeBag = DisposeBag()
    private let realmManager = RealmManager.shared

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let catSelected: Observable<Cat?>
        let addLogButtonTapped: Observable<Void>
    }

    struct Output {
        let catsWithSelection: Driver<[CatWithSelection]>
        let visitLogs: Driver<[VisitLog]>
        let presentLogRecord: Driver<Cat?>
    }

    private let catsRelay = BehaviorRelay<[Cat]>(value: [])
    private let visitLogRelay = BehaviorRelay<[VisitLog]>(value: [])
    private let selectedCatRelay = BehaviorRelay<Cat?>(value: nil)

    func transform(_ input: Input) -> Output {
        // NotificationCenter로 데이터 갱신 트리거
        let refreshTrigger = NotificationCenter.default.rx
            .notification(NSNotification.Name("RefreshVisitLogs"))
            .map { _ in () }
        
        // viewDidLoad와 viewWillAppear 둘 다에서 데이터 로드
        Observable.merge(input.viewDidLoad, input.viewWillAppear, refreshTrigger)
            .subscribe(with: self) { owner, _ in
                owner.loadCats()
                // 현재 선택된 고양이에 맞는 데이터 로드
                owner.loadVisitLogs(for: owner.selectedCatRelay.value)
            }
            .disposed(by: disposeBag)

        // 고양이 선택 시 처리
        input.catSelected
            .do { [weak self] cat in
                guard let self else { return }
                self.selectedCatRelay.accept(cat)
            }
            .subscribe(with: self) { owner, selectedCat in
                owner.loadVisitLogs(for: selectedCat)
            }
            .disposed(by: disposeBag)

        // 고양이 목록과 선택 상태를 결합
        let catsWithSelection = Observable.combineLatest(
            catsRelay.asObservable(),
            selectedCatRelay.asObservable()
        )
        .map { cats, selectedCat -> [CatWithSelection] in
            // "전체" 항목 추가
            var result: [CatWithSelection] = [
                CatWithSelection(cat: nil, isSelected: selectedCat == nil)
            ]
            
            // 각 고양이와 선택 상태 추가
            let catItems = cats.map { cat in
                CatWithSelection(
                    cat: cat,
                    isSelected: selectedCat?.id == cat.id
                )
            }
            result.append(contentsOf: catItems)
            
            return result
        }
        .asDriver(onErrorJustReturn: [])

        // 로그 추가 버튼 탭 시 선택된 고양이 전달
        let presentLogRecord = input.addLogButtonTapped
            .withLatestFrom(selectedCatRelay.asObservable())
            .asDriver(onErrorJustReturn: nil)

        return Output(
            catsWithSelection: catsWithSelection,
            visitLogs: visitLogRelay.asDriver(),
            presentLogRecord: presentLogRecord
        )
    }

    private func loadCats() {
        let cats = realmManager.fetchAllCats()
        catsRelay.accept(cats)

        if let currentSelectedCat = selectedCatRelay.value,
           (currentSelectedCat.isInvalidated || !cats.contains(where: { $0.id == currentSelectedCat.id })) {
            selectedCatRelay.accept(nil)
        }
    }

    private func loadAllVisitLogs() {
        let visitLogs = realmManager.fetchAllVisitLogs()
        visitLogRelay.accept(visitLogs)
    }

    private func loadVisitLogs(for cat: Cat?) {
        guard let cat = cat else {
            loadAllVisitLogs()
            return
        }

        guard !cat.isInvalidated else {
            loadAllVisitLogs()
            return
        }
        
        let visitLogs = realmManager.fetchVisitLogs(forCatId: cat.id)
        visitLogRelay.accept(visitLogs)
    }
}
