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
        let cats = Array(realmManager.fetchAllCats())
        catsRelay.accept(cats)

        // 선택된 고양이가 삭제되었다면 "전체" 선택
        if let currentSelectedCat = selectedCatRelay.value,
           !cats.contains(where: { $0.id == currentSelectedCat.id }) {
            selectedCatRelay.accept(nil)  // "전체"로 설정
        }
    }

    private func loadAllVisitLogs() {
        // Realm에서 최신 데이터를 가져와서 Array로 변환
        let results = realmManager.fetchAllVisitLogs()
        let visitLogs = Array(results)
        visitLogRelay.accept(visitLogs)
    }

    private func loadVisitLogs(for cat: Cat?) {
        guard let cat = cat else {
            loadAllVisitLogs()
            return
        }

        // Realm에서 최신 고양이 객체를 다시 가져오기
        guard let freshCat = realmManager.fetchCat(by: cat.id) else {
            loadAllVisitLogs()
            return
        }
        
        let visitLogs = Array(freshCat.visitLogs)
            .sorted { $0.date > $1.date }
        visitLogRelay.accept(visitLogs)
    }
}
